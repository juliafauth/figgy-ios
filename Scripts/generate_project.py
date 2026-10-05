#!/usr/bin/env python3
"""Build the checked-in Xcode project without XcodeGen or CocoaPods."""
from pathlib import Path
import hashlib, json, plistlib, re, xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1]
O={}
def uid(key): return hashlib.sha1(key.encode()).hexdigest()[:24].upper()
def obj(key,isa,**fields):
    k=uid(key);O[k]={'isa':isa,**fields};return k
class Ref(str): pass
def ref(v): return Ref(v)
def render(v,level=0):
    if isinstance(v,Ref):return str(v)
    if isinstance(v,str):return json.dumps(v)
    if isinstance(v,bool):return '1' if v else '0'
    if isinstance(v,int):return str(v)
    if isinstance(v,list):return '(\n'+''.join('\t'*(level+1)+render(x,level+1)+',\n' for x in v)+'\t'*level+')'
    return '{\n'+''.join('\t'*(level+1)+k+' = '+render(val,level+1)+';\n' for k,val in v.items())+'\t'*level+'}'
files={}
def file(path,typ=None):
    if path in files:return files[path]
    typ=typ or {'swift':'sourcecode.swift','plist':'text.plist.xml','xcassets':'folder.assetcatalog','xcconfig':'text.xcconfig'}.get(path.split('.')[-1],'text')
    files[path]=obj('file:'+path,'PBXFileReference',lastKnownFileType=typ,path=path,sourceTree='<group>');return files[path]
config=file('Config/Signing.xcconfig')
packages={
 'libwebp':obj('package:webp','XCRemoteSwiftPackageReference',repositoryURL='https://github.com/SDWebImage/libwebp-Xcode.git',requirement={'kind':'exactVersion','version':'1.5.0'}),
 'ZIPFoundation':obj('package:zip','XCRemoteSwiftPackageReference',repositoryURL='https://github.com/weichsel/ZIPFoundation.git',requirement={'kind':'exactVersion','version':'0.9.20'})}
common=['Shared/Models.swift','Shared/StickerStore.swift']
processing=['Shared/ImageProcessor.swift','Shared/PackTransfer.swift']
app=sorted(str(p.relative_to(R)) for p in (R/'App').glob('*.swift'))
targets={
 'Figgy':{'sources':common+processing+app,'product':'com.apple.product-type.application','ext':'app','plist':'Config/App-Info.plist','deps':['FiggyMessages','FiggyShare'],'packages':['libwebp','ZIPFoundation'],'resources':['Resources/Catalog','Resources/Assets.xcassets','Resources/PrivacyInfo.xcprivacy']},
 'FiggyMessages':{'sources':common+['MessagesExtension/MessagesViewController.swift'],'product':'com.apple.product-type.app-extension.messages','ext':'appex','plist':'Config/Messages-Info.plist','deps':[],'packages':[],'resources':['Resources/MessagesAssets.xcassets','Resources/PrivacyInfo.xcprivacy']},
 'FiggyShare':{'sources':common+processing+['ShareExtension/ShareViewController.swift'],'product':'com.apple.product-type.app-extension','ext':'appex','plist':'Config/Share-Info.plist','deps':[],'packages':['libwebp','ZIPFoundation'],'resources':['Resources/PrivacyInfo.xcprivacy']},
 'FiggyLocal':{'sources':common+processing+app,'product':'com.apple.product-type.application','ext':'app','plist':'Config/App-Info.plist','deps':[],'packages':['libwebp','ZIPFoundation'],'resources':['Resources/Catalog','Resources/Assets.xcassets','Resources/PrivacyInfo.xcprivacy']},
 'FiggyTests':{'sources':['Tests/FiggyTests.swift'],'product':'com.apple.product-type.bundle.unit-test','ext':'xctest','deps':['Figgy'],'packages':['ZIPFoundation'],'resources':[]}}
products={n:obj('product:'+n,'PBXFileReference',explicitFileType={'app':'wrapper.application','appex':'wrapper.app-extension','xctest':'wrapper.cfbundle'}[t['ext']],includeInIndex=0,path=n+'.'+t['ext'],sourceTree='BUILT_PRODUCTS_DIR') for n,t in targets.items()}
ids={n:uid('target:'+n) for n in targets}
for n,t in targets.items():
    builds=[]
    for p in t['sources']:
        builds.append(ref(obj('build:'+n+':'+p,'PBXBuildFile',fileRef=ref(file(p)))))
    phases=[ref(obj('sources:'+n,'PBXSourcesBuildPhase',buildActionMask=2147483647,files=builds,runOnlyForDeploymentPostprocessing=0))]
    pres=[]
    for p in t['resources']:
        typ='folder' if p=='Resources/Catalog' else ('folder.assetcatalog' if p.endswith('xcassets') else 'text.xml')
        pres.append(ref(obj('resource:'+n+':'+p,'PBXBuildFile',fileRef=ref(file(p,typ)))))
    phases.append(ref(obj('resources:'+n,'PBXResourcesBuildPhase',buildActionMask=2147483647,files=pres,runOnlyForDeploymentPostprocessing=0)))
    pdeps=[];frameworks=[]
    for package in t['packages']:
        product=obj('pkgproduct:'+n+package,'XCSwiftPackageProductDependency',package=ref(packages[package]),productName=package)
        pdeps.append(ref(product));frameworks.append(ref(obj('pkgbuild:'+n+package,'PBXBuildFile',productRef=ref(product))))
    phases.append(ref(obj('frameworks:'+n,'PBXFrameworksBuildPhase',buildActionMask=2147483647,files=frameworks,runOnlyForDeploymentPostprocessing=0)))
    if n=='Figgy':
        embeds=[ref(obj('embed:'+d,'PBXBuildFile',fileRef=ref(products[d]),settings={'ATTRIBUTES':['RemoveHeadersOnCopy']})) for d in t['deps']]
        phases.append(ref(obj('embedphase','PBXCopyFilesBuildPhase',buildActionMask=2147483647,dstPath='',dstSubfolderSpec=13,files=embeds,name='Embed App Extensions',runOnlyForDeploymentPostprocessing=0)))
    depends=[]
    for d in t['deps']:
        proxy=obj('proxy:'+n+d,'PBXContainerItemProxy',containerPortal=ref(uid('project')),proxyType=1,remoteGlobalIDString=ref(ids[d]),remoteInfo=d)
        depends.append(ref(obj('depend:'+n+d,'PBXTargetDependency',target=ref(ids[d]),targetProxy=ref(proxy))))
    configs=[]
    for build in ['Debug','Release']:
        settings={'PRODUCT_NAME':'$(TARGET_NAME)','SWIFT_VERSION':'5.0','TARGETED_DEVICE_FAMILY':'1,2','IPHONEOS_DEPLOYMENT_TARGET':'17.0','CODE_SIGN_STYLE':'Automatic','DEVELOPMENT_TEAM':'$(FIGGY_TEAM)','MARKETING_VERSION':'1.0.0','CURRENT_PROJECT_VERSION':'1','SWIFT_EMIT_LOC_STRINGS':'YES','SUPPORTED_PLATFORMS':'iphoneos iphonesimulator','SUPPORTS_MACCATALYST':'NO','ENABLE_USER_SCRIPT_SANDBOXING':'YES'}
        suffix={'Figgy':'figgy','FiggyMessages':'figgy.Messages','FiggyShare':'figgy.Share','FiggyLocal':'figgy.local','FiggyTests':'figgy.Tests'}[n]
        settings['PRODUCT_BUNDLE_IDENTIFIER']='$(FIGGY_BUNDLE_PREFIX).'+suffix
        settings['GENERATE_INFOPLIST_FILE']='NO'
        settings['LD_RUNPATH_SEARCH_PATHS']=['$(inherited)', '@executable_path/Frameworks']
        if t.get('plist'):settings['INFOPLIST_FILE']=t['plist']
        if n in ['Figgy','FiggyMessages','FiggyShare']:settings['CODE_SIGN_ENTITLEMENTS']='Config/Figgy.entitlements'
        if n in ['Figgy','FiggyLocal']:
            settings['ASSETCATALOG_COMPILER_APPICON_NAME']='AppIcon';settings['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME']='AccentColor'
            settings['INFOPLIST_KEY_CFBundleDisplayName']='Figgy' if n=='Figgy' else 'Figgy Local'
        if n=='FiggyMessages':settings['ASSETCATALOG_COMPILER_APPICON_NAME']='iMessage App Icon'
        if n in ['FiggyMessages','FiggyShare']:
            settings['APPLICATION_EXTENSION_API_ONLY']='YES';settings['SKIP_INSTALL']='YES'
            settings['LD_RUNPATH_SEARCH_PATHS'].append('@executable_path/../../Frameworks')
        if n=='FiggyLocal':settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS']='$(inherited) FIGGY_LOCAL_ONLY'
        if n=='FiggyTests':
            settings.update({'GENERATE_INFOPLIST_FILE':'YES','BUNDLE_LOADER':'$(TEST_HOST)','TEST_HOST':'$(BUILT_PRODUCTS_DIR)/Figgy.app/Figgy'})
        configs.append(ref(obj('config:'+n+build,'XCBuildConfiguration',baseConfigurationReference=ref(config),buildSettings=settings,name=build)))
    configsID=obj('configs:'+n,'XCConfigurationList',buildConfigurations=configs,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
    obj('target:'+n,'PBXNativeTarget',buildConfigurationList=ref(configsID),buildPhases=phases,buildRules=[],dependencies=depends,name=n,packageProductDependencies=pdeps,productName=n,productReference=ref(products[n]),productType=t['product'])
# File navigator includes all source and configuration files, with root-relative paths.
for p in ['Config/Figgy.entitlements','Config/App-Info.plist','Config/Messages-Info.plist','Config/Share-Info.plist']:file(p)
groups=[]
for group in ['App','Shared','MessagesExtension','ShareExtension','Resources','Config','Tests']:
    children=[ref(f) for p,f in files.items() if p.startswith(group+'/')]
    groups.append(ref(obj('group:'+group,'PBXGroup',children=children,name=group,sourceTree='<group>')))
productGroup=obj('group:products','PBXGroup',children=[ref(p) for p in products.values()],name='Products',sourceTree='<group>')
mainGroup=obj('group:main','PBXGroup',children=groups+[ref(productGroup)],sourceTree='<group>')
pc=[]
for name in ['Debug','Release']:
    settings={'SDKROOT':'iphoneos','CLANG_ENABLE_MODULES':'YES','CLANG_ENABLE_OBJC_ARC':'YES','SWIFT_VERSION':'5.0','IPHONEOS_DEPLOYMENT_TARGET':'17.0','SWIFT_STRICT_CONCURRENCY':'minimal','SWIFT_OPTIMIZATION_LEVEL':'-Onone' if name=='Debug' else '-O','ENABLE_TESTABILITY':'YES' if name=='Debug' else 'NO','DEBUG_INFORMATION_FORMAT':'dwarf' if name=='Debug' else 'dwarf-with-dsym','SWIFT_ACTIVE_COMPILATION_CONDITIONS':'DEBUG' if name=='Debug' else ''}
    pc.append(ref(obj('projconfig:'+name,'XCBuildConfiguration',buildSettings=settings,name=name)))
pcl=obj('projconfigs','XCConfigurationList',buildConfigurations=pc,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
obj('project','PBXProject',attributes={'BuildIndependentTargetsInParallel':'YES','LastUpgradeCheck':'1600','TargetAttributes':{ids['FiggyTests']:{'TestTargetID':ref(ids['Figgy'])}}},buildConfigurationList=ref(pcl),compatibilityVersion='Xcode 14.0',developmentRegion='pt-BR',hasScannedForEncodings=0,knownRegions=['pt-BR','en','Base'],mainGroup=ref(mainGroup),productRefGroup=ref(productGroup),projectDirPath='',projectRoot='',packageReferences=[ref(p) for p in packages.values()],targets=[ref(k) for k in ids.values()])
proj=R/'Figgy.xcodeproj';proj.mkdir(exist_ok=True)
(proj/'project.pbxproj').write_text('// !$*UTF8*$!\n'+render({'archiveVersion':1,'classes':{},'objectVersion':56,'objects':O,'rootObject':ref(uid('project'))})+'\n')
def scheme(name,testing=False):
    root=ET.Element('Scheme',{'LastUpgradeVersion':'1600','version':'1.3'})
    action=ET.SubElement(root,'BuildAction',{'parallelizeBuildables':'YES','buildImplicitDependencies':'YES'})
    entries=ET.SubElement(action,'BuildActionEntries')
    entry=ET.SubElement(entries,'BuildActionEntry',{'buildForTesting':'YES','buildForRunning':'YES','buildForProfiling':'YES','buildForArchiving':'YES','buildForAnalyzing':'YES'})
    def buildref(parent,n):ET.SubElement(parent,'BuildableReference',{'BuildableIdentifier':'primary','BlueprintIdentifier':ids[n],'BuildableName':n+'.'+targets[n]['ext'],'BlueprintName':n,'ReferencedContainer':'container:Figgy.xcodeproj'})
    buildref(entry,name)
    test=ET.SubElement(root,'TestAction',{'buildConfiguration':'Debug','selectedDebuggerIdentifier':'Xcode.DebuggerFoundation.Debugger.LLDB','selectedLauncherIdentifier':'Xcode.IDEFoundation.Launcher.LLDB','shouldUseLaunchSchemeArgsEnv':'YES'})
    ts=ET.SubElement(test,'Testables')
    if testing:buildref(ET.SubElement(ts,'TestableReference',{'skipped':'NO'}),'FiggyTests')
    launch=ET.SubElement(root,'LaunchAction',{'buildConfiguration':'Debug','selectedDebuggerIdentifier':'Xcode.DebuggerFoundation.Debugger.LLDB','selectedLauncherIdentifier':'Xcode.IDEFoundation.Launcher.LLDB','launchStyle':'0','useCustomWorkingDirectory':'NO','ignoresPersistentStateOnLaunch':'NO','debugServiceExtension':'internal','allowLocationSimulation':'YES'})
    buildref(ET.SubElement(launch,'BuildableProductRunnable',{'runnableDebuggingMode':'0'}),name)
    profile=ET.SubElement(root,'ProfileAction',{'buildConfiguration':'Release','shouldUseLaunchSchemeArgsEnv':'YES','savedToolIdentifier':'','useCustomWorkingDirectory':'NO','debugServiceExtension':'internal'})
    buildref(ET.SubElement(profile,'BuildableProductRunnable',{'runnableDebuggingMode':'0'}),name)
    ET.SubElement(root,'AnalyzeAction',{'buildConfiguration':'Debug'});ET.SubElement(root,'ArchiveAction',{'buildConfiguration':'Release','revealArchiveInOrganizer':'YES'})
    folder=proj/'xcshareddata'/'xcschemes';folder.mkdir(parents=True,exist_ok=True)
    ET.indent(root);ET.ElementTree(root).write(folder/(name+'.xcscheme'),encoding='utf-8',xml_declaration=True)
scheme('Figgy',True);scheme('FiggyLocal')
base={'CFBundleInfoDictionaryVersion':'6.0','CFBundleDevelopmentRegion':'pt_BR','CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)','CFBundleName':'$(PRODUCT_NAME)','CFBundleExecutable':'$(EXECUTABLE_NAME)','CFBundleShortVersionString':'$(MARKETING_VERSION)','CFBundleVersion':'$(CURRENT_PROJECT_VERSION)','FiggyAppGroup':'$(FIGGY_APP_GROUP)'}
def plist(name,data):(R/'Config'/name).write_bytes(plistlib.dumps(data,sort_keys=False))
plist('App-Info.plist',{**base,'CFBundleDisplayName':'Figgy','CFBundlePackageType':'APPL','LSRequiresIPhoneOS':True,'UILaunchScreen':{},'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'],'UISupportedInterfaceOrientations~ipad':['UIInterfaceOrientationPortrait','UIInterfaceOrientationPortraitUpsideDown','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'],'LSApplicationQueriesSchemes':['whatsapp'],'LSSupportsOpeningDocumentsInPlace':True,'CFBundleDocumentTypes':[{'CFBundleTypeName':'Figgy Sticker Pack','CFBundleTypeRole':'Editor','LSHandlerRank':'Owner','LSItemContentTypes':['com.figgy.stickerpack']}],'UTExportedTypeDeclarations':[{'UTTypeIdentifier':'com.figgy.stickerpack','UTTypeDescription':'Figgy Sticker Pack','UTTypeConformsTo':['public.zip-archive'],'UTTypeTagSpecification':{'public.filename-extension':['figpack'],'public.mime-type':'application/vnd.figgy.stickerpack'}}]})
plist('Messages-Info.plist',{**base,'CFBundleDisplayName':'Figgy','CFBundlePackageType':'XPC!','MSSupportedPresentationContexts':['MSMessagesAppPresentationContextMessages','MSMessagesAppPresentationContextMedia'],'NSExtension':{'NSExtensionPointIdentifier':'com.apple.message-payload-provider','NSExtensionPrincipalClass':'$(PRODUCT_MODULE_NAME).MessagesViewController'}})
plist('Share-Info.plist',{**base,'CFBundleDisplayName':'Salvar no Figgy','CFBundlePackageType':'XPC!','NSExtension':{'NSExtensionPointIdentifier':'com.apple.share-services','NSExtensionPrincipalClass':'$(PRODUCT_MODULE_NAME).ShareViewController','NSExtensionAttributes':{'NSExtensionActivationRule':{'NSExtensionActivationSupportsImageWithMaxCount':30,'NSExtensionActivationSupportsFileWithMaxCount':30}}}})
plist('Figgy.entitlements',{'com.apple.security.application-groups':['$(FIGGY_APP_GROUP)']})
privacy={'NSPrivacyTracking':False,'NSPrivacyTrackingDomains':[],'NSPrivacyCollectedDataTypes':[],'NSPrivacyAccessedAPITypes':[{'NSPrivacyAccessedAPIType':'NSPrivacyAccessedAPICategoryFileTimestamp','NSPrivacyAccessedAPITypeReasons':['C617.1']},{'NSPrivacyAccessedAPIType':'NSPrivacyAccessedAPICategorySystemBootTime','NSPrivacyAccessedAPITypeReasons':['35F9.1']}]}
# File timestamps are used by archive/file APIs. No system uptime API is used by Figgy.
privacy['NSPrivacyAccessedAPITypes']=privacy['NSPrivacyAccessedAPITypes'][:1]
(R/'Resources'/'PrivacyInfo.xcprivacy').write_bytes(plistlib.dumps(privacy))
print('Generated Figgy.xcodeproj: full app, two extensions, free local app, XCTest target.')

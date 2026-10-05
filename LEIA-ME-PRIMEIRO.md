# Figgy

Um app iOS em Swift e SwiftUI para criar figurinhas preservando a imagem inteira, organizar packs e compartilhá-los. A interface está em português, com lilás, rosa, verde e amarelo.

**Este pacote contém o projeto-fonte, uma prévia interativa e a compilação automática pelo GitHub Actions.** Ainda não contém um IPA compilado: não houve acesso a Xcode ou iPhone durante esta entrega.

Para instalar pelo Windows sem ter um Mac, siga **`INSTALAR-NO-IPHONE-SEM-MAC.md`**. O workflow usa um Mac do GitHub e gera `Figgy.ipa` para o AltStore Classic assinar e instalar com sua conta gratuita. Inclui testes, app completo e as duas extensões. Não exige certificados ou senha Apple no GitHub.

## Começar agora no seu Windows

1. Extraia o ZIP.
2. Abra `Preview/Figgy-Preview.html` no Chrome, Edge ou Firefox.
3. Navegue, baixe um pack da galeria, escolha uma imagem, adicione texto e salve sua criação.
4. Em Meus packs, baixe um `.figpack`. Esse é o mesmo formato que o app nativo importa.

A prévia é um arquivo independente, funciona sem internet e mantém suas criações no armazenamento do navegador. Ela **não instala o app**, não executa as extensões do iPhone e não adiciona packs ao WhatsApp. Os botões correspondentes explicam a ação nativa. O recorte opcional de fundo também depende do app iOS. Limpar os dados do navegador apaga os packs da prévia, portanto exporte os que quiser guardar.

## O que está implementado no projeto iOS

| Recurso | Implementação |
| --- | --- |
| Criar figurinhas | Fotos/Arquivos, imagem inteira, legenda, tamanho e posição do texto, cores e margens |
| Remover fundo | Opcional, usando Vision; o botão Restaurar recupera a imagem original |
| Packs | Criar, renomear, excluir, adicionar/remover figurinhas; até 30 por pack |
| Galeria grátis | 3 packs originais, 18 figurinhas incluídas, busca e categorias; funciona offline |
| Mais packs | Importar `.figpack`, imagens e ZIP; abrir catálogos JSON por HTTPS e baixar seus packs |
| Compartilhar | Exportar `.figpack` pela folha de compartilhamento do iPhone; receber por Arquivos ou extensão Compartilhar |
| WhatsApp | Conversão real para WebP, ícone PNG e handoff pelo protocolo oficial do WhatsApp |
| Teclado do iPhone | Extensão Messages com `MSStickerBrowserView`, contexto media habilitado e biblioteca compartilhada por App Group |
| Privacidade | Processamento local; sem contas, anúncios, assinatura, analytics ou upload automático de fotos |

**A coleção no teclado é o pack do Figgy, fornecido por uma extensão.** O app não grava diretamente na coleção de Live Stickers do Fotos. A disponibilidade do painel e do envio varia conforme o app em que você estiver digitando.

A versão inicial trabalha com **figurinhas estáticas**. GIF, APNG e WebP animados são recusados, evitando transformar uma animação em uma imagem sem avisar. ZIPs genéricos importam imagens estáticas; exportações do WhatsApp priorizam arquivos `STK-…` quando eles existem.

## Quando você conseguir o Mac

Requisitos: Xcode com SDK compatível com a versão de iOS do seu iPhone, iOS 17 ou superior, internet para resolver duas dependências gratuitas e seu Apple Account.

1. Extraia a pasta Figgy no Mac e abra `Figgy.xcodeproj`.
2. Espere o Xcode resolver `libwebp` 1.5.0 e `ZIPFoundation` 0.9.20 pelo Swift Package Manager. Não é necessário CocoaPods ou XcodeGen.
3. Em **Xcode → Settings → Accounts**, adicione sua conta Apple.
4. Abra `Config/Signing.xcconfig`. Troque `FIGGY_BUNDLE_PREFIX` por um identificador exclusivo, por exemplo `com.juliafauth`. Defina `FIGGY_APP_GROUP` como `group.com.juliafauth.figgy`. Defina `FIGGY_TEAM` com o Team ID da sua conta, se disponível. Alternativamente, selecione o mesmo Team em Signing & Capabilities para todos os targets.
5. Nos targets **Figgy**, **FiggyMessages** e **FiggyShare**, mantenha Automatically manage signing e habilite o mesmo App Group. Confirme que os três usam o mesmo identificador definido no passo anterior. O Xcode pode precisar registrar o grupo para sua conta.
6. Escolha o scheme **Figgy**, selecione seu iPhone, conecte por cabo, confie no Mac e ative Developer Mode se o iPhone solicitar. Clique em **Run ▶︎**.
7. Abra o app, baixe um pack e siga o roteiro de teste abaixo.

Você também pode configurar todos os identificadores pelo Terminal do Mac:

```bash
python3 Scripts/configure.py --bundle-prefix com.juliafauth --team SEUTEAMID0
```

Use seu Team ID real de 10 caracteres; `SEUTEAMID0` é apenas um exemplo.

A tabela atual da Apple inclui App Groups para Apple Accounts gratuitos. Portanto, tente primeiro o projeto completo sem pagar. A instalação para desenvolvimento continua sujeita às regras de assinatura da sua conta. Se sua instalação do Xcode não conseguir provisionar o grupo, você pode rodar o scheme **FiggyLocal**, que testa o editor, packs e exportação sem extensões ou App Group. Os dados desse modo ficam em uma instalação separada e não são compartilhados com o teclado; exporte um `.figpack` para migrar.

O app é grátis para os usuários. Distribuir pela App Store/TestFlight exige participar do Apple Developer Program, com taxa de US$ 99 por ano, salvo eventual elegibilidade a uma isenção da Apple. Nenhuma compra, conta ou publicação foi feita nesta entrega.

## Testar o requisito mais importante

1. Baixe “Só reações”, que já tem seis figurinhas.
2. Em Meus packs → Só reações → WhatsApp, confirme a adição dentro do WhatsApp. O botão só confirma que o WhatsApp foi aberto; ele não presume que você aceitou a importação.
3. Envie as figurinhas e confira a orientação da imagem, as bordas, o fundo e todos os textos.
4. Abra Mensagens, abra o teclado de emojis/painel Stickers e procure o Figgy. Confira as mesmas imagens inteiras.
5. Crie um meme com uma foto retangular e texto nas bordas, mantendo **Imagem inteira**. Compare as bordas no editor, WhatsApp e teclado.
6. Teste novamente em outro app que suporte o painel de stickers do iOS. Se o painel não atualizar, feche-o e reabra.
7. Exporte um `.figpack`, envie para outro aparelho com Figgy, importe-o e repita os dois destinos.
8. Teste imagens com transparência, imagem opaca, ZIP do WhatsApp, exclusão e reinício do app.

O WhatsApp exige de 3 a 30 figurinhas por pack. O exportador produz imagens 512×512, WebP até 100 KB e ícone 96×96 até 50 KB. A conversão ajusta a qualidade para caber, mas mantém todo o conteúdo. A confirmação final é responsabilidade da interface do WhatsApp.

Se o WhatsApp pedir permissão para colar dados, autorize a ação de importação que você acabou de iniciar. Se o protocolo de importação tiver mudado na versão instalada do WhatsApp, registre a versão e o erro antes de ajustar o exportador.

## Compartilhar e baixar packs existentes

- Os packs gratuitos originais vêm dentro do app. “Baixar” instala uma cópia na sua biblioteca, mesmo sem internet.
- Packs de outras pessoas entram por `.figpack`. O criador exporta e envia o arquivo; quem recebe precisa ter Figgy.
- O app também aceita um catálogo externo com links HTTPS para `.figpack`. Há documentação e um exemplo em `CATALOGOS.md`.
- Não há um feed público, cadastro de usuários ou servidor de uploads nesta entrega. O compartilhamento acontece por arquivo e por catálogos hospedados por seus criadores. Nenhum serviço pago é necessário para usar os recursos locais.
- O app não acessa os arquivos privados do WhatsApp e não copia automaticamente os Favorites. Exporte uma conversa com as figurinhas e mídia para Arquivos, quando sua versão do WhatsApp disponibilizar esse recurso; depois importe o ZIP. Disponibilidade e conteúdo da exportação devem ser conferidos no aparelho.

## Arquivos do projeto

- `App/`: telas SwiftUI, estado da biblioteca, catálogo online e integração WhatsApp.
- `Shared/`: modelos, armazenamento, processamento de imagens e importação/exportação de packs.
- `MessagesExtension/`: navegador de stickers do teclado e Messages.
- `ShareExtension/`: receber arquivos pela folha Compartilhar.
- `Config/`: assinatura, entitlements e Info.plist.
- `Resources/`: ícones, catálogo, arte original e exemplo `.figpack`.
- `Tests/`: oito testes XCTest para preservação de bordas, WebP, packs, limites, armazenamento e seleção de App Groups do AltStore.
- `Preview/`: prévia independente para Windows.
- `Scripts/`: geração do projeto/arte/prévia e verificações reproduzíveis.
- `.github/workflows/ios.yml`: testes e geração manual do IPA em runner macOS.

## Verificação e limites

Veja `VALIDACAO.md` para os resultados efetivamente executados. Análise de sintaxe não é compilação: UIKit, SwiftUI, Vision, Messages, assinatura e handoff precisam ser validados no Xcode e no iPhone. Os testes XCTest estão escritos, mas precisam ser executados no Mac.

## Fontes oficiais consultadas em 5 de outubro de 2026

- Apple, contextos Messages/media e teclado de emojis: https://developer.apple.com/documentation/messages/adding-sticker-packs-and-imessage-apps-to-the-system-stickers-app-messages-camera-and-facetime
- Apple, capacidades por modalidade de conta: https://developer.apple.com/help/account/reference/supported-capabilities-ios
- Apple, taxa anual de distribuição: https://developer.apple.com/help/account/membership/program-enrollment
- WhatsApp, requisitos de imagens e protocolo de importação no iOS: https://github.com/WhatsApp/stickers/blob/main/iOS/README.md

As instruções técnicas devem ser confrontadas com a versão do Xcode, iOS e WhatsApp usada no teste final.

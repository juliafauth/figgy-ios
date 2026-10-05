# Verificação da entrega — 5 de outubro de 2026

## Verificações executadas e aprovadas

- 15 arquivos Swift analisados pela gramática tree-sitter-swift, sem erros de sintaxe.
- `project.pbxproj` analisado como OpenStep; 144 objetos e cinco targets conferidos.
- Todos os caminhos de código e recursos do projeto existem.
- Extensão Messages configurada para os contextos Messages e media.
- Os três componentes completos usam o mesmo identificador de App Group via configuração; o target local não incorpora extensões.
- 18 imagens PNG RGBA do catálogo em 512×512, abaixo do limite de arquivo definido; três packs com títulos e imagens correspondentes.
- Arquivo de exemplo `.figpack` contém manifesto versão 1 e três imagens válidas.
- Prévia aberta em Chromium headless, com navegação, categorias, instalação de pack, explicação dos destinos nativos, editor de imagem e texto, escolha de cor, salvamento e persistência após recarregar.
- Prévia exportou um ZIP `.figpack` real, com seis PNGs e o mesmo esquema de manifesto do app iOS.
- Prévia importou o pack de exemplo.
- Sem erros de execução JavaScript nas interações testadas.
- Sem transbordamento horizontal no editor em viewport de 320 pixels.
- Capturas das três telas revisadas visualmente. As capturas são da prévia web, não do app iOS compilado.

## Verificações ainda necessárias no Mac/iPhone

- Compilação e type-check de Swift com os SDKs Apple e resolução dos pacotes no Xcode.
- Os oito testes XCTest incluídos no projeto, agora executados pelo workflow do GitHub.
- Provisionamento real com a conta Apple e ativação do App Group.
- Instalação no iPhone e disponibilidade da extensão no painel de stickers do teclado.
- Exportação/adição efetiva na versão instalada do WhatsApp, incluindo permissão de clipboard e confirmação do pack.
- Preservação de cores, transparência e orientação das imagens nos dois destinos.
- Recorte opcional com Vision e comportamento em Fotos/Arquivos/Compartilhar reais.
- Teste de catálogo HTTPS contra um servidor real de packs.

Não houve acesso a Xcode ou a um iPhone durante esta entrega. A aprovação das verificações estruturais e da prévia não garante que o binário nativo compilará ou que todas as integrações funcionarão sem ajustes na primeira execução.

Para repetir verificações estruturais, instale `pillow`, `tree-sitter`, `tree-sitter-swift` e `openstep-parser` em um ambiente Python e execute `python3 Scripts/validate_project.py`.

Para repetir a prévia, o script usa Playwright/Chromium. Defina `CODEX_PRIMARY_RUNTIME_NODE_MODULES` como a pasta node_modules com Playwright e, se necessário, `FIGGY_BROWSER` como o executável Chromium disponível. Execute da pasta que contém `Figgy`: `node Figgy/Scripts/test_preview.cjs`. O script pressupõe os caminhos do pacote para entrada e saída das capturas.

No Xcode, selecione Figgy e use Product → Test para os testes nativos. Prefira validar em simulador antes de assinar para o aparelho; confirme os dois destinos no iPhone depois.

## Atualização para GitHub Actions e AltStore

- Workflow verificado por `actionlint` 1.7.12, sem erros; gatilho manual, referências de scripts e permissões conferidos.
- Scripts Bash aprovados em `bash -n`; scripts Python de empacotamento e verificação aprovados na análise de sintaxe.
- Verificador de layout do IPA exercitado com fixtures temporárias: aceita estrutura completa e rejeita extensão ausente, grupos diferentes e assinatura ausente. Essas fixtures não são binários compilados e não foram incluídas no pacote.
- Verificações estruturais do projeto repetidas após os ajustes, com 15 arquivos Swift e 144 objetos aprovados.
- Acrescentados workflow manual em macOS, testes em simulador, archive para iPhone e empacotamento do IPA.
- O empacotamento mantém as duas extensões e assinaturas ad-hoc com App Group para que AltStore descubra e substitua as capacidades na assinatura real. Isso não autoriza instalação direta no aparelho.
- O armazenamento consulta primeiro `ALTAppGroups`, que o AltStore injeta em cada bundle ao assinar. Incluído teste para prioridade, fallback e remoção de grupos repetidos.
- Incluído roteiro `INSTALAR-NO-IPHONE-SEM-MAC.md` para execução pela própria usuária, sem conectar a conta GitHub ao ChatGPT.
- A compilação Xcode, codesign real e instalação pelo AltStore ainda não foram executadas. As verificações locais não substituem esses passos.

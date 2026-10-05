# Instalar Figgy pelo Windows, sem Mac

Você vai usar o GitHub para compilar no macOS e o AltStore Classic para assinar e instalar no seu iPhone. Requisitos: Windows, cabo USB, iPhone com iOS 17 ou superior, conta GitHub e Apple Account gratuita.

O ZIP contém código e a automação, não um IPA já compilado. Não foi executado Xcode nesta entrega. O primeiro teste nativo acontecerá quando você executar a automação abaixo.

## 1. Preparar o repositório

1. Extraia `Figgy-iOS.zip` no Windows. Abra a pasta `Figgy` que foi extraída.
2. Acesse https://github.com/new e entre ou crie uma conta gratuita.
3. Nomeie o repositório `figgy-ios`. Escolha **Public** se estiver confortável em deixar o código visível: os runners padrão do GitHub Actions são gratuitos em repositórios públicos. Para código privado, há uma franquia gratuita; sem forma de pagamento cadastrada, o uso para quando ela acaba. Não é necessário contratar um plano.
4. Marque **Add a README file** e clique em **Create repository**.
5. Clique em **Add file → Upload files**. Arraste o conteúdo de dentro de `Figgy`, incluindo as pastas `App`, `Shared`, `Config`, `Resources`, `Scripts`, `Tests`, `MessagesExtension`, `ShareExtension`, `Figgy.xcodeproj` e `.github`, além dos arquivos de texto. Clique em **Commit changes** e confirme a branch `main`.

**Confira a posição das pastas:** na tela inicial do repositório precisam aparecer `App`, `Scripts` e `Figgy.xcodeproj` diretamente. Se aparecer só uma pasta `Figgy`, os arquivos ficaram um nível abaixo do necessário. O GitHub não compila um ZIP enviado como arquivo: é preciso enviar os arquivos extraídos.

O pacote tem menos de 100 arquivos úteis e cada um é menor que 25 MB, dentro dos limites do envio pelo navegador. Não envie pastas de compilação ou arquivos temporários.

### Se `.github` não aparecer após o envio

O Explorador de Arquivos pode ocultar a pasta ou o navegador pode não incluí-la. Você pode criar o workflow pela interface:

1. No repositório, clique em **Add file → Create new file**.
2. No campo do nome, escreva exatamente `.github/workflows/ios.yml`.
3. No Windows, abra `Figgy/.github/workflows/ios.yml` com o Bloco de Notas. Copie todo o conteúdo e cole no editor do GitHub. Se a pasta não aparecer no Explorador, digite esse caminho na barra de endereço ou ative a visualização de itens ocultos.
4. Clique em **Commit changes**, salvando em `main`.

Você não precisa editar os identificadores do app nem colocar conta/senha Apple, certificado ou token no repositório. O AltStore fará a assinatura depois.

## 2. Gerar o arquivo do aplicativo

1. Abra a aba **Actions** no seu repositório. Se o GitHub pedir para habilitar Actions, habilite.
2. Na lateral, escolha **Gerar Figgy para iPhone**.
3. Clique em **Run workflow**, mantenha a branch `main` e a opção de testes marcada; clique no botão verde **Run workflow**.
4. Abra a execução criada e acompanhe o job **Testar e gerar IPA**. Ele resolve as dependências, executa oito testes XCTest, compila o app e inclui as duas extensões.
5. Quando aparecer a marca verde de sucesso, abra o resumo da execução. Na seção **Artifacts**, clique em **Figgy-iPhone**.
6. Extraia o ZIP baixado. Dentro dele estará `Figgy.ipa`, o arquivo que será aberto pelo AltStore. O `.sha256` é apenas o comprovante de integridade.

Os downloads ficam disponíveis por três dias. Guarde uma cópia do IPA; renovar o app no AltStore não exige compilar novamente.

**Se aparecer vermelho:** não há um IPA aprovado para instalar. Baixe o artefato `Figgy-logs` ou abra a etapa que falhou e copie o primeiro erro do Xcode. Envie esse log na conversa para a correção. Desmarcar os testes não corrige um erro de compilação.

**Se o workflow não aparecer:** confirme que `.github/workflows/ios.yml` está na raiz e na branch padrão `main`. Abra o arquivo e confira que o conteúdo foi enviado como texto YAML, não como ZIP.

## 3. Instalar AltStore Classic no iPhone

Use o [guia oficial para Windows](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows), que fornece os downloads corretos de iTunes, iCloud e AltServer. Escolha **AltStore Classic**.

1. Instale iTunes e iCloud nas versões indicadas pelo guia e instale AltServer no Windows.
2. Abra AltServer como administrador. Conecte o iPhone desbloqueado por cabo e toque em **Confiar**.
3. No iTunes, ative a sincronização por Wi-Fi para o aparelho.
4. No ícone do AltServer perto do relógio, escolha **Install AltStore → seu iPhone**. Entre com sua Apple Account no AltServer.
5. No iPhone, confie no perfil em **Ajustes → Geral → VPN e Gerenciamento de Dispositivo**. Ative **Ajustes → Privacidade e Segurança → Modo de Desenvolvedor**, reiniciando quando solicitado.

## 4. Instalar o Figgy

1. Deixe AltServer aberto no Windows, com o iPhone por cabo ou na mesma rede Wi-Fi.
2. Transfira `Figgy.ipa` para o app **Arquivos** do iPhone, por exemplo usando iCloud Drive. Outra opção é baixar o artefato pelo Safari, entrando no GitHub, e tocar no ZIP em Arquivos para extraí-lo.
3. Abra **AltStore → My Apps → +** e escolha `Figgy.ipa`. Entre com a mesma Apple Account se solicitado.
4. **Mantenha as extensões** se o AltStore perguntar. Removê-las tira o painel de figurinhas e o recebimento pelo menu Compartilhar. Aguarde a instalação e abra Figgy.

O app e as duas extensões usam três App IDs; sua conta precisa ter espaço para eles no limite gratuito. Se o AltStore indicar que os IDs acabaram, consulte **My Apps → View App IDs** e espere os anteriores expirarem.

## 5. Conferir no aparelho e renovar

1. No Figgy, baixe o pack **Só reações**.
2. Abra-o em **Meus packs → WhatsApp** e confirme a importação na tela do WhatsApp. Envie uma figurinha para conferir imagem e orientação.
3. Abra Mensagens, o teclado de emojis/painel de figurinhas e procure Figgy. Confira que o pack baixado aparece. Teste depois no aplicativo em que você pretende usar o painel.
4. Crie uma figurinha sua, exporte um `.figpack` e importe novamente para conferir o compartilhamento.

Com conta Apple gratuita, a instalação expira após sete dias. Antes disso, abra **AltStore → My Apps → Refresh All**, com AltServer acessível pelo cabo ou pela mesma rede. Não é preciso baixar outro IPA toda semana. Exporte seus packs antes de desinstalar o app.

Se o Figgy abrir, mas o teclado não mostrar sua biblioteca, mantenha as duas extensões e envie o aviso exibido pelo Figgy e a versão do iOS. O projeto usa os App Groups provisionados pelo AltStore; esse compartilhamento ainda precisa ser confirmado no iPhone.

## Fontes oficiais conferidas em 5 de outubro de 2026

- [GitHub: cobrança e uso gratuito do Actions](https://docs.github.com/en/billing/concepts/product-billing/github-actions)
- [GitHub: enviar arquivos e pastas](https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository)
- [GitHub: executar workflow manualmente](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow)
- [AltStore: instalação no Windows](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows)
- [AltStore: renovação](https://faq.altstore.io/altstore-classic/your-altstore)
- [AltStore: conexão ao AltServer](https://faq.altstore.io/altstore-classic/altserver)
- [AltStore: limites de App IDs](https://faq.altstore.io/altstore-classic/app-ids)
- [AltStore: grupos reais registrados durante a assinatura](https://github.com/altstoreio/AltStore/blob/develop/AltStore/Operations/ResignAppOperation.swift)

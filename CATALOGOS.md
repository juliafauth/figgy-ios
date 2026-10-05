# Catálogos gratuitos por link

O app aceita catálogos de packs por HTTPS. Não é necessário criar contas no Figgy para publicar ou consumir um catálogo.

1. Exporte um `.figpack` no Figgy. O pack deve conter imagens estáticas e pode ter de 1 a 30 figurinhas; para WhatsApp precisa de pelo menos 3.
2. Disponibilize o arquivo em um servidor/site que você controla e permite download direto por HTTPS. Não use uma página de login ou uma página HTML de compartilhamento como URL do arquivo.
3. Publique um JSON como este no mesmo servidor:

```json
{
  "version": 1,
  "packs": [
    {
      "id": "minhas-reacoes-v1",
      "name": "Minhas reações",
      "author": "Julia",
      "category": "Reações",
      "color": "CDB9F4",
      "url": "https://seu-dominio.example/minhas-reacoes.figpack"
    }
  ]
}
```

O domínio acima é um exemplo, não um serviço instalado. Use uma URL real sob seu controle. Os links no JSON precisam ser absolutos e usar HTTPS. O catálogo tem até 100 packs e 256 KB; cada download tem até 30 MB. O app verifica os arquivos antes de gravá-los na biblioteca.

4. Compartilhe o link direto para esse JSON. No Figgy, abra Explorar → Recebeu um catálogo?, cole o link e escolha Baixar grátis.

Não há pagamento, upload de fotos privadas ou servidor central do Figgy. O dono do catálogo é responsável pelo conteúdo e pelas permissões de distribuição das imagens que publicar.

## Formato .figpack

É um ZIP com `manifest.json` e arquivos PNG dentro de `images/`. O manifesto versão 1 contém `format: "figgy-pack"`, nome, autor, cor em hexadecimal de seis caracteres e uma lista de figurinhas com `file`, `title` e `emojis`.

Os caminhos de imagem aceitos têm o formato `images/nome-seguro.png`, sem pastas adicionais ou segmentos `..`. Os nomes reais são substituídos por UUIDs quando o pack é instalado. Cada imagem precisa ficar abaixo de 500.000 bytes; o exportador nativo cuida disso.

`Resources/Example.figpack` contém três figurinhas originais prontas para importar. Packs de outros apps com formatos próprios não são anunciados como compatíveis; exporte as imagens ou importe um ZIP de imagens.

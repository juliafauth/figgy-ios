# Dependências e arte

O código Figgy foi escrito para este projeto. As 18 figurinhas do catálogo são desenhos geométricos originais gerados pelo script `Scripts/generate_assets.py`; não são packs de memes baixados de terceiros.

O projeto resolve dependências abertas e gratuitas pelo Swift Package Manager:

- libwebp 1.5.0, via SDWebImage/libwebp-Xcode: https://github.com/SDWebImage/libwebp-Xcode — libwebp tem licença BSD e avisos próprios. Preserve os arquivos de licença fornecidos pela dependência ao distribuir.
- ZIPFoundation 0.9.20: https://github.com/weichsel/ZIPFoundation — licença MIT. Preserve o aviso fornecido pelo pacote.

A prévia inclui JSZip 3.x, com seu aviso de licença dentro do script incorporado. JSZip é disponibilizado sob MIT ou GPLv3; esta prévia usa a opção MIT. Fonte: https://github.com/Stuk/jszip.

As imagens usam fonte DejaVu Sans quando geradas no Linux, ou Arial no Mac. A fonte não é distribuída como arquivo de fonte; o catálogo contém imagens rasterizadas. Verifique a licença da fonte que escolher ao regenerar arte para outra distribuição.

O projeto implementa o protocolo público de stickers do WhatsApp; não inclui as classes do exemplo da Meta. Não implica afiliação com Apple ou WhatsApp.

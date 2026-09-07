# Errata — *Zero to Store with AI* / *Do Zero à Loja com IA*

Every chapter of the book ends with a **Verified on** line: the date, the
Flutter version, and the kit tag the chapter was checked against. That line is
there because things move — a Flutter release, a screen in the Play Console, a
store policy. This page is where the book catches up.

## Where corrections live

Corrections are **Issues in this repository**, labelled
[`errata`](https://github.com/frcc24/flutter-store-kit/issues?q=label%3Aerrata).
The issue tracker has search and history, so a correction is easy to find and
carries the date it was made. There is no separate errata site to keep in sync.

The pinned issue **Errata — first edition** links the confirmed ones, newest
first.

## Reporting one

Open an issue with:

- the **chapter** and the **page** (the PDF page number, or the section title in
  the EPUB);
- what the book says;
- what happened when you followed it — the command you ran and the output, when
  there is one.

A correction to the book is different from a bug in the kit: a kit bug is a
normal issue without the label. Both are welcome.

## What counts as an errata

- A step that no longer works: a renamed console screen, a changed policy, an
  option that moved.
- A factual error: a wrong threshold, a wrong API name, a number that does not
  match the source.
- A prompt that does not produce what the chapter says it produces.

What is **not** an errata: a version bump that changes nothing in the
instructions, and a difference between the kit's `main` and the tag a chapter
pins — the tag is the chapter's snapshot, on purpose.

## Update policy

- **Same edition:** if you bought the book, corrections to that edition cost
  nothing. Hotmart and Gumroad send the updated files to buyers; on Kindle,
  Amazon notifies buyers of significant updates and the file can be re-downloaded.
- **New edition:** a new edition is a new product. It is not a paid correction —
  it is a rewrite with new chapters or a new Flutter major.
- The kit's `CHANGELOG.md` records what changed in the code, with dates.

---

## Em português

Cada capítulo termina com a linha **Verificado em**: a data, a versão do Flutter
e a tag do kit conferida. Este é o lugar onde o livro se atualiza depois dessa
data.

**Onde ficam as correções.** Nas Issues deste repositório, com o rótulo
[`errata`](https://github.com/frcc24/flutter-store-kit/issues?q=label%3Aerrata).
A Issue fixada *Errata — first edition* junta as confirmadas, da mais nova para
a mais antiga.

**Como reportar.** Abra uma Issue com o capítulo, a página (o número no PDF ou o
título da seção no EPUB), o que o livro diz e o que aconteceu quando você
seguiu — com o comando e a saída, quando houver.

**O que conta como errata.** Um passo que deixou de funcionar (tela renomeada no
Console, política mudada, opção que mudou de lugar); um erro de fato (limiar
errado, nome de API errado, número que não bate com a fonte); um prompt que não
entrega o que o capítulo diz. Não conta: uma versão nova que não muda a
instrução, nem a diferença entre a `main` do kit e a tag que o capítulo fixa — a
tag é a fotografia daquele capítulo, de propósito.

**Política de atualização.** Quem comprou recebe as correções da mesma edição
sem pagar de novo, pelo canal onde comprou: a Hotmart e o Gumroad reenviam os
arquivos; na Kindle, a Amazon avisa quando a atualização é relevante. Uma edição
nova é um produto novo, não uma correção paga.

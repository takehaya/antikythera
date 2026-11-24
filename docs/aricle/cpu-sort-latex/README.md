# CPU副テーマ報告書

- `main.tex`、`sections/`：LaTeX原稿。
- `build/main.pdf`：この原稿から生成したPDF。
- `figures/`、`code/`、`evidence/`：既存の図、コード・実験結果。evidence配下にあるv5等のファイルは過去の実験・出典照合記録であり、現在の原稿の文章検証ではない。
- このディレクトリは報告書の再生成用で、VivadoプロジェクトやWDBの再現用ではない。

`evidence/package-rebuild-check.json` は推敲前の配布版を再ビルドした際の比較記録である。

## Macでレポートをビルドする

専用Dockerイメージを使う。Docker Desktopが起動していて、既存の `cpu-report-tex:v7-20261026` がある場合：

```sh
docker image inspect cpu-report-tex:v7-20261026 >/dev/null
python3 docker-build.py
```

出力は `build/main.pdf`。MacにTeXをインストールする必要はない。既存イメージがない場合の構築ファイル `Dockerfile`、`install-tex.sh`、`build-image.py` も同梱したが、その手順は依存パッケージを取得して新しいイメージを作る。同梱のPDFはMac上のDockerで生成した。表紙には未確定項目がある。

## MacでCPUデモを再実行する

Vivado/XSimはMacネイティブではなく、既存のLinux用Docker環境を使う。別添の「Vivado 操作ガイド」（2026年10月26日）の起動手順とTclを使う。期待結果は `passed=1`、配列0〜9、366サイクル。これは保存済みの実行結果で、今回のMac再実行結果ではない。

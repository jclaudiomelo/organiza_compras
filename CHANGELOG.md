# Changelog

## [1.0.2+3] - Atualização de Correção de Bugs (Leitor SEFAZ)

### Correções (Fixes)
* **Permissão de Rede no Android:** Adicionada a configuração `android:usesCleartextTraffic="true"` nos arquivos `AndroidManifest.xml` (modos `main` e `debug`). Isso corrige o erro `net::ERR_CLEARTEXT_NOT_PERMITTED` ao consultar notas fiscais (NFC-e) em portais da SEFAZ que ainda utilizam o protocolo HTTP sem criptografia (como o do estado do Ceará).
* **Configuração de Build (Play Store):** Documentado e resolvido o erro de compilação de release (`Target aot_android_asset_bundle failed: Error: Avoid non-constant invocations of IconData`). Agora a compilação do App Bundle deve ser feita utilizando o comando `flutter build appbundle --no-tree-shake-icons` para suportar os ícones dinâmicos das categorias.

### Modificações Técnicas
* **Versão:** App version incrementado no `pubspec.yaml` de `1.0.1+2` para `1.0.2+3` em preparação para envio ao Google Play Console.
* **Cache Limpo:** Executado `flutter clean` para garantir que o cache de compilação force a nova regra do AndroidManifest na próxima execução ou build.

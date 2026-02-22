# mizchi/glfw - GLFW MoonBit Bindings

## プロジェクト構成

- `src/glfw.mbt` - MoonBit FFI 宣言 + pub ラッパー関数
- `src/glfw_stub.m` - Objective-C ネイティブスタブ（macOS Cocoa）
- `src/moon.pkg` - パッケージ設定（native-only）

## ビルド・確認

```bash
just check    # moon check --target native
just fmt      # moon fmt + diff check
```

## 注意事項

- native ターゲット専用。JS/WASM ビルドは非対応
- `extern "C"` を含む `.mbt` は `moon.pkg` の `targets` で native に制限すること（`supported-targets` だけでは不十分）
- consumer 側で `cc-link-flags` に `-lglfw` が必要（link flags は依存から伝播しない）
- C stub は Objective-C (macOS Cocoa)。Windows/Linux 対応は未実装

## kagura からの開発

kagura 側で `moon.mod.json` をローカルパスに切り替えて開発:

```json
"mizchi/glfw": { "path": "../glfw-mbt" }
```

修正後は `moon publish` してバージョン番号に戻す。

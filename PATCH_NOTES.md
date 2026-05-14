# penas_calc — Patch: foto de perfil (web + mobile)

## Como aplicar
```bash
cp -r /home/vanessa/Downloads/penas_calc_patch/. /home/vanessa/repositories/penas_calc
flutter pub get
```

## Arquivo alterado

### `lib/widgets/avatar_perfil.dart`
- Web: abre file picker do navegador, salva como data URL base64 (sem dependência de File I/O)
- Mobile/Desktop: bottom sheet com câmera, galeria e opção de remover
- Ícone do badge adaptado: 📤 upload na web, 📷 câmera no mobile
- Exibição via `MemoryImage` (web/data URL) ou `FileImage` (mobile)

# Bundled Inter fonts

Inter is licensed under the SIL Open Font License 1.1. The complete license is
included in `OFL.txt` and registered with Flutter's application license registry.

Source: [Inter in the Google Fonts repository](https://github.com/google/fonts/tree/main/ofl/inter).
The original file is `Inter[opsz,wght].ttf`. The bundled upright TTF files are
static instances at optical size 14 and weights 400, 500, 600, and 700, generated
with FontTools 4.66.1. They retain the original font copyright and license metadata.

Flutter loads the four files through the `Inter` family in `pubspec.yaml`. No
network connection, Google Fonts runtime package, or font-generation tooling is
needed to run or build the application.

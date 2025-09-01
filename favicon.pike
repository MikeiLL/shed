#!/usr/bin/env pike
/*
Accept up to five arguments:
    text: displayed in center of icon,
    background-color: default white,
    text-color: default black,
    shape: displayed within a square,
    shape-color: default light grey
Produce four matching image.ico files in following sizes:
    16x16
    32x32
    48x48
    64x64
Enhancement: Also output a manifest.json file:
{
  "name": "",
  "short_name": "",
  "icons": [
    {
      "src": "/android-chrome-192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/android-chrome-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ],
  "theme_color": "#ffffff",
  "background_color": "#ffffff",
  "display": "standalone"
}
*/

int main(int argc, array(string) argv) {
  mapping args = Arg.parse(argv); // parsed arguments
  if (args->help) {
    write(#"USAGE: %s [text] [primaryColor] [textcolor] [shape] [secondaryColor]
    SUPPORTED SHAPES: circle or default to none
    (Leave off last two parameters for no circle.)
    OPTIONAL FLAGS
    --help
    --fontpath
    EXAMPLES:
      %<s C magenta aliceblue
      %<s X magenta rebeccapurple circle darkblue
    ", basename(argv[0]));
    return 0;
  }
  string fontspath = args->fontpath || "/Users/mikekilmer/Library/Fonts";
  Image.Fonts.set_font_dirs(({fontspath}));
  if (args->listfonts) {
    write("Fonts in %s: %O\n", fontspath, sort(indices(Image.Fonts.list_fonts())));
  }
  if (args->shapes) {
    write("Shape Options %s: %O\n", fontspath, sort(({
      "square (default)",
      "hsplit (split horizontal)",
      "vsplit (split vertical)",
      "dsplitl (split diagonal left top to right bottom)",
      "dsplitr (split diagonal right top to left bottom)",
      "hstripe (stripe horizontal)",
      "vstripe (stripe vertical)",
      "star (of David)",
      "diamond (rotated square)"
    })));
  }
  constant IMAGE_SIZE = 64;
  [string text,
  string primaryColor,
  string textcolor,
  string shape,
  string secondaryColor] = args[Arg.REST] + ({"M", "#fff", "#000", "none", "#bbb"})[sizeof(args[Arg.REST])..];
  int desired_height = IMAGE_SIZE - 4; //2px padding top and bottom
  Image.Image ltr;
  // Find the biggest letter of specified font that fits within threshold
  for (int sz = IMAGE_SIZE / 2; sz < 1024; ++sz) {
    object font = Image.Fonts.open_font("Lato", sz, Image.Fonts.BOLD);
    Image.Image tryme = font->write(text)->autocrop();
    if (tryme->ysize() <= desired_height) ltr = tryme;
    if (tryme->ysize() >= desired_height) break;
  }
  // https://pike.lysator.liu.se/generated/manual/modref/ex/predef_3A_3A/Image/Color.html#Color
  array secondarycolor = Colors.parse_color(secondaryColor); // RGB array
  Image.Image icon = Image.Image(64, 64, @Colors.parse_color(primaryColor));
  array txtcol = Colors.parse_color(textcolor);

  switch (shape) {
    case "circle":
      icon->setcolor(@secondarycolor);
      constant RADIUS = IMAGE_SIZE/2 - 1;
      constant RSQ = RADIUS ** 2;
      for (int x = 0; x < IMAGE_SIZE / 2; ++x)
        for (int y = 0; y < IMAGE_SIZE / 2; ++y)
          if (x*x + y*y < RSQ) {
            icon->setpixel(IMAGE_SIZE / 2 + x, IMAGE_SIZE / 2 + y); // lower right
            icon->setpixel(IMAGE_SIZE / 2 + x, IMAGE_SIZE / 2 - y); // upper right
            icon->setpixel(IMAGE_SIZE / 2 - x, IMAGE_SIZE / 2 + y); // lower left
            icon->setpixel(IMAGE_SIZE / 2 - x, IMAGE_SIZE / 2 - y); // upper left
          }
      break;
    case "hsplit": icon->box(IMAGE_SIZE / 2,0, IMAGE_SIZE,IMAGE_SIZE, @secondarycolor); werror("Split H"); break;
    case "vsplit": icon->box(0, IMAGE_SIZE /2, IMAGE_SIZE,IMAGE_SIZE, @secondarycolor); werror("Split V"); break;
    case "dsplitl": icon->setcolor(@secondarycolor)->polyfill( ({ 0,0, IMAGE_SIZE,0, IMAGE_SIZE,IMAGE_SIZE }) ); break;
    case "dsplitr": icon->setcolor(@secondarycolor)->polyfill( ({ 0,0, IMAGE_SIZE,0, 0,IMAGE_SIZE }) ); break;
    case "hstripe": case "vstripe": {
      constant STRIPE_COUNT = 6; //total, 3 of each colour
      for(int i=1; i < STRIPE_COUNT; i+=2) { // paint stripes 1 three and five (0 - 5)
        int start = IMAGE_SIZE * i / STRIPE_COUNT;
        int end = IMAGE_SIZE * (i + 1) / STRIPE_COUNT;
        if (shape == "hstripe") icon->box(0, start, IMAGE_SIZE, end, @secondarycolor);
        else icon->box(start, 0, end, IMAGE_SIZE, @secondarycolor);
      }
      break;
    }
    case "star": break;
    case "diamond": break;
    case "none": case "square": break;
    default: exit(1, "Unrecognized shape %O\n", shape);
  }
  icon->paste_mask(Image.Image(ltr->xsize(), ltr->ysize(), @txtcol),ltr, (IMAGE_SIZE - ltr->xsize()) / 2, (IMAGE_SIZE - ltr->ysize()) / 2);
  Stdio.write_file("favicon.png",Image.PNG.encode(icon));
}

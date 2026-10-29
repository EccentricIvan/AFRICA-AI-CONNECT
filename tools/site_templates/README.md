# Site templates generator

The ten landing-page templates in `assets/templates/` (bakery, hotel,
fitness, salon, church, realtor, techstartup, ngo, portfolio, school) are
generated from one design system so they stay consistent:

```
node tools/site_templates/build.mjs assets/templates
```

- `build.mjs` — the shared CSS, page layout (header with mobile menu, main,
  contact section, footer), SEO/accessibility head, and a check that every
  template keeps exactly the `{{placeholders}}` the site builder fills
  (`lib/features/site_builder/site_template_catalog.dart`). It refuses to
  write a template whose placeholders changed.
- `content.mjs` — each template's sections and copy.

Keep the `header`, `nav`, `.btn` and `.hero` hooks: the builder's colour
picker overrides their backgrounds. Do not use "hero" inside other class
names (`[class*=hero]` would recolour them). Everything is offline: no web
fonts, CDNs or images from the internet.

The dashboard-style templates (agritech, edudash, smartedu, taskflow,
saasai) are hand-written; `test/builder_templates_test.dart` checks all
fifteen meet the same standards.

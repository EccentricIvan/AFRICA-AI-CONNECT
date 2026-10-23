// Content for each landing-page template. Placeholders ({{key}}) must match
// what the site builder fills for that template (build.mjs checks).

const hero = ({ eyebrow, title, lead, primary, secondary, card }) => `<section class="hero" aria-labelledby="hero-title">
  <div class="wrap grid">
    <div>
      <span class="eyebrow">${eyebrow}</span>
      <h1 id="hero-title">${title}</h1>
      <p class="lead">${lead}</p>
      <div class="actions">
        <a class="btn" href="${primary[0]}">${primary[1]}</a>
        <a class="ghost" href="${secondary[0]}">${secondary[1]}</a>
      </div>
    </div>
    <aside class="panel-card" aria-label="${card.label}">
      <h3>${card.title}</h3>
      <ul class="facts">
        ${card.facts.map(([ico, b, s]) => `<li><span class="ico" aria-hidden="true">${ico}</span><div><b>${b}</b><span>${s}</span></div></li>`).join('\n        ')}
      </ul>
    </aside>
  </div>
</section>`;

const head = (eyebrow, id, title, lead) =>
  `<div class="section-head"><span class="eyebrow">${eyebrow}</span><h2 id="${id}-title">${title}</h2>${lead ? `<p>${lead}</p>` : ''}</div>`;

const section = (id, cls, inner, eyebrow, title, lead) => `<section class="section${cls ? ' ' + cls : ''}" id="${id}" aria-labelledby="${id}-title">
  <div class="wrap">
    ${head(eyebrow, id, title, lead)}
    ${inner}
  </div>
</section>`;

const cards = (items) => `<div class="grid-3">
      ${items.map(([ico, t, p, price]) => `<article class="card"><div class="ico" aria-hidden="true">${ico}</div><h3>${t}</h3><p>${p}</p>${price ? `<span class="price-tag">${price}</span>` : ''}</article>`).join('\n      ')}
    </div>`;

const stats = (items) => `<section class="stats" aria-label="Key numbers">
  <div class="wrap grid-3">
    ${items.map(([n, l]) => `<div class="stat"><div class="num">${n}</div><div class="lbl">${l}</div></div>`).join('\n    ')}
  </div>
</section>`;

const plans = (items) => `<div class="plans">
      ${items.map(([name, amount, per, feats, featured]) => `<article class="plan${featured ? ' featured' : ''}"><h3>${name}</h3><div class="amount">${amount}<small style="font-size:.9rem;font-weight:600;color:var(--muted)"> ${per}</small></div><ul>${feats.map((f) => `<li>${f}</li>`).join('')}</ul><a class="btn" href="#contact">Choose ${name}</a></article>`).join('\n      ')}
    </div>`;

const quotes = (items) => `<div class="grid-3">
      ${items.map(([q, who]) => `<blockquote class="quote"><div class="stars" aria-label="5 out of 5">★★★★★</div><p>${q}</p><footer>— ${who}</footer></blockquote>`).join('\n      ')}
    </div>`;

const faq = (items) => `<div class="faq">
      ${items.map(([q, a]) => `<details><summary>${q}</summary><p>${a}</p></details>`).join('\n      ')}
    </div>`;

const gallery = (items) => `<div class="gallery">
      ${items.map(([ico, label]) => `<div class="tile" data-icon="${ico}" role="img" aria-label="${label}"><span>${label}</span></div>`).join('\n      ')}
    </div>`;

const split = (id, cls, eyebrow, title, text, checks, icon) => `<section class="section${cls ? ' ' + cls : ''}" id="${id}" aria-labelledby="${id}-title">
  <div class="wrap split">
    <div>
      <span class="eyebrow">${eyebrow}</span>
      <h2 id="${id}-title">${title}</h2>
      <p>${text}</p>
      <ul class="checks">${checks.map((c) => `<li>${c}</li>`).join('')}</ul>
    </div>
    <div class="visual" aria-hidden="true">${icon}</div>
  </div>
</section>`;

const band = (title, text, cta) => `<section class="section" aria-label="${title}">
  <div class="wrap">
    <div class="band"><div><h2>${title}</h2><p>${text}</p></div><a class="btn" href="${cta[0]}">${cta[1]}</a></div>
  </div>
</section>`;

export const templates = [
  {
    id: 'bakery', name: '{{business_name}}', icon: '🍞', navCta: 'Order now',
    title: '{{business_name}} — {{tagline}}', description: '{{description}}',
    palette: { primary: '#9a3412', dark: '#7c2d12', accent: '#d97706', soft: '#ffedd5' },
    nav: [['menu', 'Menu'], ['about', 'About'], ['reviews', 'Reviews'], ['faq', 'FAQ']],
    sections: [
      hero({ eyebrow: 'Freshly baked every morning', title: '{{tagline}}', lead: '{{description}}',
        primary: ['#menu', 'See our menu'], secondary: ['#contact', 'Order a cake'],
        card: { label: 'Why customers love us', title: 'Why customers love us', facts: [
          ['🌾', 'Local ingredients', 'Flour, eggs and fruit from nearby farms'],
          ['⏰', 'Baked at dawn', 'Bread out of the oven by 7 AM'],
          ['🎂', 'Custom cakes', 'Birthdays, weddings and graduations'],
        ] } }),
      section('menu', '', `<div class="rows">
      ${[['Freshly baked bread', 'Warm, crusty loaves made daily with local flour', 'UGX 5,000'],
         ['Chocolate cake', 'Rich, moist sponge with chocolate buttercream', 'UGX 15,000'],
         ['Meat pie', 'Flaky pastry filled with seasoned minced beef', 'UGX 3,000'],
         ['Cinnamon rolls', 'Soft, sweet rolls with a cream cheese glaze', 'UGX 4,000'],
         ['Samosas (3 pieces)', 'Crispy pastry with spiced vegetables or beef', 'UGX 3,000']]
        .map(([t, p, price]) => `<div class="row"><div><h3>${t}</h3><p>${p}</p></div><span class="price-tag">${price}</span></div>`).join('\n      ')}
    </div>`, 'Menu', 'Baked fresh today', 'Prices include VAT. Ask about bulk orders for events and offices.'),
      split('about', 'alt', 'Our story', 'Made from scratch, with love', '{{about}}',
        ['Everything made on site, every day', 'No preservatives or shortcuts', 'Friendly service and fair prices'], '🥐'),
      section('reviews', '', quotes([
        ['The best bread in town. I stop by every morning before work.', 'Grace N., regular customer'],
        ['They made our wedding cake and every guest asked where it came from.', 'Daniel & Ruth'],
        ['Fresh, affordable and always served with a smile.', 'Brian K.'],
      ]), 'Reviews', 'What our customers say'),
      section('faq', 'alt', faq([
        ['Do you take orders for events?', 'Yes. Order cakes and platters at least 48 hours ahead by phone or WhatsApp.'],
        ['Do you deliver?', 'We deliver within town for a small fee. Ask when you call to order.'],
        ['Can you make eggless or sugar-free cakes?', 'Yes, tell us what you need and we will bake it specially.'],
      ]), 'FAQ', 'Questions we hear often'),
    ],
    contact: { address: '{{address}}', phone: '{{phone}}', title: 'Visit us or place an order', lead: 'Open daily from 7:00 AM to 8:00 PM.',
      formTitle: 'Order by phone', callNote: 'Call or WhatsApp us to order fresh bread, pastries or a custom cake.',
      extra: [['⏰', 'Opening hours', 'Every day, 7:00 AM – 8:00 PM']] },
    footerAbout: '{{tagline}}',
  },
  {
    id: 'hotel', name: '{{hotel_name}}', icon: '🏨', navCta: 'Book a room',
    title: '{{hotel_name}} — {{tagline}}', description: '{{description}}',
    palette: { primary: '#0f3d3e', dark: '#082f30', accent: '#c2410c', soft: '#ccfbf1' },
    nav: [['rooms', 'Rooms'], ['amenities', 'Amenities'], ['reviews', 'Reviews'], ['faq', 'FAQ']],
    sections: [
      hero({ eyebrow: 'Welcome', title: '{{tagline}}', lead: '{{description}}',
        primary: ['#rooms', 'View rooms'], secondary: ['#contact', 'Check availability'],
        card: { label: 'At a glance', title: 'Your stay includes', facts: [
          ['🍳', 'Breakfast included', 'Freshly prepared every morning'],
          ['📶', 'Free fast Wi-Fi', 'In every room and the lobby'],
          ['🚗', 'Airport transfers', 'Arranged on request'],
        ] } }),
      section('rooms', '', plans([
        ['Standard', '{{price_standard}}', '/ night', ['Queen bed', 'En-suite bathroom', 'Breakfast for one'], false],
        ['Deluxe', '{{price_deluxe}}', '/ night', ['King bed and city view', 'Breakfast for two', 'Mini bar and work desk'], true],
        ['Presidential', '{{price_presidential}}', '/ night', ['Private suite and lounge', 'Butler service', 'Airport pick-up'], false],
      ]), 'Rooms', 'Rooms and suites', 'Every room is cleaned daily and comes with air conditioning and a flat-screen TV.'),
      section('amenities', 'alt', cards([
        ['🏊', 'Swimming pool', 'Heated outdoor pool, open from 6 AM to 10 PM.'],
        ['🍽️', 'Restaurant & bar', 'Local and international dishes, all day.'],
        ['💆', 'Spa & wellness', 'Massages and treatments by appointment.'],
        ['🏢', 'Conference hall', 'Meetings and events for up to 200 guests.'],
      ]), 'Amenities', 'Everything for a comfortable stay'),
      section('reviews', '', quotes([
        ['Spotless rooms, delicious breakfast and the friendliest staff we have met.', 'Amina, Nairobi'],
        ['Perfect for business trips: quiet, fast Wi-Fi and close to town.', 'James O.'],
        ['We held our wedding reception here. Everything was handled beautifully.', 'The Ssekandi family'],
      ]), 'Reviews', 'Guests love staying with us'),
      section('faq', 'alt', faq([
        ['What time are check-in and check-out?', 'Check-in is from 2:00 PM and check-out is by 11:00 AM. Ask about early check-in.'],
        ['Is parking available?', 'Yes, secure parking is free for guests.'],
        ['How do I pay?', 'We accept cash, cards and mobile money.'],
      ]), 'FAQ', 'Good to know before you arrive'),
    ],
    contact: { address: '{{address}}', phone: '{{phone}}', email: '{{email}}', title: 'Book your stay', lead: 'Tell us your dates and we will confirm availability within the hour.',
      formTitle: 'Reservation request', subject: 'Room booking', button: 'Request booking', prefill: 'Arrival date:\nDeparture date:\nNumber of guests:\nRoom type:' },
    footerAbout: '{{tagline}}',
  },
  {
    id: 'fitness', name: '{{gym_name}}', icon: '💪', navCta: 'Join today',
    title: '{{gym_name}} — {{tagline}}', description: '{{description}}',
    palette: { primary: '#111827', dark: '#030712', accent: '#ef4444', soft: '#fee2e2' },
    nav: [['classes', 'Classes'], ['membership', 'Membership'], ['reviews', 'Results'], ['faq', 'FAQ']],
    sections: [
      hero({ eyebrow: 'Train with us', title: '{{tagline}}', lead: '{{description}}',
        primary: ['#membership', 'See membership'], secondary: ['#contact', 'Book a free session'],
        card: { label: 'Opening hours', title: 'Open for you', facts: [
          ['⏰', 'Hours', '{{hours}}'],
          ['🏋️', 'Modern equipment', 'Free weights, machines and cardio'],
          ['🧑‍🏫', 'Certified trainers', 'Personal plans for every level'],
        ] } }),
      section('classes', '', cards([
        ['🔥', 'HIIT', 'Fast, high-energy sessions that burn fat and build stamina.'],
        ['🧘', 'Yoga & stretch', 'Improve flexibility, balance and recovery.'],
        ['🥊', 'Boxing', 'Learn technique while getting fit and strong.'],
        ['🏃', 'Running club', 'Weekly group runs for every pace.'],
      ]), 'Classes', 'Group classes every day', 'All classes are included with Premium membership.'),
      section('membership', 'alt', plans([
        ['Student', '{{price_student}}', '/ month', ['Gym floor access', 'Valid student ID', 'Off-peak hours'], false],
        ['Basic', '{{price_basic}}', '/ month', ['Gym floor access', 'Locker and showers', 'Fitness assessment'], false],
        ['Premium', '{{price_premium}}', '/ month', ['Everything in Basic', 'All group classes', 'Monthly trainer session'], true],
      ]), 'Membership', 'Simple, honest pricing', 'No joining fee this month. Cancel anytime.'),
      section('reviews', '', quotes([
        ['I lost 12 kg in four months thanks to the trainers and the community.', 'Sarah M.'],
        ['Clean, well-equipped and the coaches really care about your progress.', 'Peter A.'],
        ['The boxing class is the best part of my week.', 'Joan K.'],
      ]), 'Results', 'Real members, real results'),
      section('faq', 'alt', faq([
        ['I am a beginner. Can I join?', 'Absolutely. Every new member gets a free assessment and a plan that suits their level.'],
        ['Do you offer personal training?', 'Yes, one-to-one sessions can be booked with any of our trainers.'],
        ['Can I pay with mobile money?', 'Yes, we accept mobile money, cash and cards.'],
      ]), 'FAQ', 'Questions before you start'),
    ],
    contact: { address: '{{address}}', phone: '{{phone}}', title: 'Start your journey', lead: 'Drop in or call us to book a free first session.',
      formTitle: 'Book a free session', callNote: 'Call or WhatsApp us and we will set up your free first session and fitness assessment.',
      extra: [['⏰', 'Hours', '{{hours}}']] },
    footerAbout: '{{tagline}}',
  },
  {
    id: 'salon', name: '{{salon_name}}', icon: '💇', navCta: 'Book now',
    title: '{{salon_name}} — {{tagline}}', description: '{{description}}',
    palette: { primary: '#86198f', dark: '#701a75', accent: '#db2777', soft: '#fae8ff' },
    nav: [['services', 'Services'], ['about', 'About'], ['gallery', 'Gallery'], ['reviews', 'Reviews']],
    sections: [
      hero({ eyebrow: 'Beauty & care', title: '{{tagline}}', lead: '{{description}}',
        primary: ['#services', 'See services'], secondary: ['#contact', 'Book an appointment'],
        card: { label: 'Opening hours', title: 'Opening hours', facts: [
          ['📅', 'Monday – Friday', '{{hours_weekday}}'],
          ['🛍️', 'Saturday', '{{hours_saturday}}'],
          ['☀️', 'Sunday', '{{hours_sunday}}'],
        ] } }),
      section('services', '', cards([
        ['💇', 'Hair styling', 'Cuts, braids, weaves, locs and treatments.', '{{price_hair}}'],
        ['💅', 'Nails', 'Manicures, pedicures, gel and acrylics.', '{{price_nails}}'],
        ['💄', 'Make-up', 'Everyday, bridal and event make-up.', '{{price_makeup}}'],
        ['🧖', 'Facials', 'Deep cleansing and glow treatments.', '{{price_facial}}'],
      ]), 'Services', 'Our services', 'Prices are starting prices. Final price depends on style and length.'),
      split('about', 'alt', 'About us', 'Where you come first', '{{about}}',
        ['Experienced, friendly stylists', 'Quality, skin-friendly products', 'Clean, relaxing space'], '✨'),
      section('gallery', '', gallery([['💇🏾‍♀️', 'Braids & locs'], ['💅', 'Gel nails'], ['👰🏾', 'Bridal looks'], ['🧖🏾‍♀️', 'Facial glow']]), 'Gallery', 'Recent work'),
      section('reviews', 'alt', quotes([
        ['My braids lasted for weeks and still looked fresh. I will be back!', 'Linda A.'],
        ['They did my bridal make-up and I felt beautiful all day.', 'Miriam K.'],
        ['Relaxing, professional and on time. Highly recommend.', 'Esther N.'],
      ]), 'Reviews', 'Happy clients'),
    ],
    contact: { address: '{{address}}', phone: '{{phone}}', title: 'Book your appointment', lead: 'Walk-ins welcome, but booking guarantees your time.',
      formTitle: 'Book by phone', callNote: 'Call or WhatsApp us with the service and time you would like.',
      extra: [['⏰', 'Hours', 'Mon–Fri {{hours_weekday}} · Sat {{hours_saturday}} · Sun {{hours_sunday}}']] },
    footerAbout: '{{tagline}}',
  },
  {
    id: 'church', name: '{{church_name}}', icon: '⛪', navCta: 'Plan a visit',
    title: '{{church_name}} — {{motto}}', description: '{{description}}',
    palette: { primary: '#1e3a8a', dark: '#172554', accent: '#ca8a04', soft: '#dbeafe' },
    nav: [['services', 'Services'], ['ministries', 'Ministries'], ['word', 'Word'], ['faq', 'New here?']],
    sections: [
      hero({ eyebrow: 'Welcome home', title: '{{motto}}', lead: '{{description}}',
        primary: ['#services', 'Service times'], secondary: ['#contact', 'Plan your visit'],
        card: { label: 'Service times', title: 'Join us this week', facts: [
          ['🙏', 'Sunday service', '{{time_sunday}}'],
          ['📖', 'Bible study', '{{time_bible}}'],
          ['🎶', 'Youth fellowship', '{{time_youth}}'],
        ] } }),
      section('services', '', cards([
        ['🙏', 'Sunday worship', 'Praise, prayer and the Word. {{time_sunday}}.'],
        ['📖', 'Bible study', 'Grow deeper in scripture together. {{time_bible}}.'],
        ['🎶', 'Youth fellowship', 'Faith, friendship and fun for young people. {{time_youth}}.'],
      ]), 'Gatherings', 'Service times', 'Everyone is welcome. Come as you are.'),
      section('ministries', 'alt', cards([
        ['👶', 'Children', 'Safe, joyful Sunday school for ages 3 to 12.'],
        ['🤝', 'Outreach', 'Serving families and the community around us.'],
        ['🎤', 'Choir & worship', 'Lead the church in praise every Sunday.'],
        ['💬', 'Counselling', 'Prayer and pastoral care when you need it.'],
      ]), 'Ministries', 'Find your place to serve'),
      `<section class="section" id="word" aria-labelledby="word-title">
  <div class="wrap">
    <div class="band" style="flex-direction:column;align-items:flex-start">
      <span class="eyebrow" style="background:rgba(255,255,255,.16);color:#fff">Verse of the week</span>
      <h2 id="word-title">“{{verse}}”</h2>
      <p>— {{verse_ref}}</p>
    </div>
  </div>
</section>`,
      section('faq', 'alt', faq([
        ['What should I expect on my first visit?', 'A warm welcome, uplifting worship and a message from the Bible. Services last about two hours.'],
        ['Is there something for my children?', 'Yes. Sunday school runs during the main service.'],
        ['What should I wear?', 'Come as you are. There is no dress code.'],
      ]), 'New here?', 'Your first visit'),
    ],
    contact: { address: '{{address}}', phone: '{{phone}}', email: '{{email}}', title: 'We would love to meet you', lead: 'Send us a message, a prayer request or plan your first visit.',
      formTitle: 'Send a message or prayer request', subject: 'Message from the website', button: 'Send message' },
    footerAbout: '{{motto}}',
  },
  {
    id: 'realtor', name: '{{company_name}}', icon: '🏡', navCta: 'Talk to an agent',
    title: '{{company_name}} — {{tagline}}', description: '{{description}}',
    palette: { primary: '#1f2937', dark: '#111827', accent: '#0d9488', soft: '#ccfbf1' },
    nav: [['listings', 'Listings'], ['services', 'Services'], ['reviews', 'Reviews'], ['faq', 'FAQ']],
    sections: [
      hero({ eyebrow: 'Trusted property experts', title: '{{tagline}}', lead: '{{description}}',
        primary: ['#listings', 'Browse properties'], secondary: ['#contact', 'Book a viewing'],
        card: { label: 'Our track record', title: 'Our track record', facts: [
          ['🏠', '{{properties_sold}}', 'Properties sold'],
          ['😊', '{{clients}}', 'Happy clients'],
          ['📆', '{{years_exp}}', 'Years of experience'],
        ] } }),
      section('listings', '', `<div class="grid-3">
      ${[1, 2, 3].map((i) => `<article class="card"><div class="visual" style="aspect-ratio:16/10;font-size:3rem;margin-bottom:16px" aria-hidden="true">${['🏡', '🏢', '🏘️'][i - 1]}</div><h3>{{prop${i}_name}}</h3><p>📍 {{prop${i}_location}}</p><p>🛏️ {{prop${i}_beds}} beds · 🛁 {{prop${i}_baths}} baths · 📐 {{prop${i}_size}}</p><span class="price-tag">{{prop${i}_price}}</span></article>`).join('\n      ')}
    </div>`, 'Listings', 'Featured properties', 'Verified titles, honest prices and viewings at your convenience.'),
      section('services', 'alt', cards([
        ['🔑', 'Buying', 'We find homes that match your budget and check every title.'],
        ['💰', 'Selling', 'Accurate valuations and marketing that reaches serious buyers.'],
        ['📋', 'Renting & management', 'Tenant screening, rent collection and maintenance.'],
      ]), 'Services', 'How we help'),
      stats([['{{properties_sold}}', 'Properties sold'], ['{{clients}}', 'Happy clients'], ['{{years_exp}}', 'Years in business']]),
      section('reviews', '', quotes([
        ['They found us the perfect family home and handled all the paperwork.', 'The Okello family'],
        ['Sold my apartment in three weeks at a great price.', 'Ruth N.'],
        ['Honest agents who answer the phone. Rare and appreciated!', 'Michael T.'],
      ]), 'Reviews', 'What clients say'),
      section('faq', 'alt', faq([
        ['Do you verify land titles?', 'Yes. Every property we list has its title checked before it is advertised.'],
        ['What are your fees?', 'Our commission is agreed in writing before any work starts. No hidden charges.'],
        ['Can I arrange a viewing at the weekend?', 'Yes, viewings are available seven days a week.'],
      ]), 'FAQ', 'Buying and selling questions'),
    ],
    contact: { address: '{{address}}', phone: '{{phone}}', email: '{{email}}', title: 'Find your next property', lead: 'Tell us what you are looking for and an agent will get back to you today.',
      formTitle: 'Talk to an agent', subject: 'Property enquiry', button: 'Send enquiry', prefill: 'I am looking to (buy / sell / rent):\nArea:\nBudget:' },
    footerAbout: '{{tagline}}',
  },
  {
    id: 'techstartup', name: '{{company_name}}', icon: '🚀', navCta: '{{cta_text}}',
    title: '{{company_name}} — {{tagline}}', description: '{{tagline}}',
    palette: { primary: '#4338ca', dark: '#312e81', accent: '#06b6d4', soft: '#e0e7ff' },
    nav: [['features', 'Features'], ['how', 'How it works'], ['pricing', 'Pricing'], ['faq', 'FAQ']],
    sections: [
      hero({ eyebrow: 'Now available', title: '{{tagline}}', lead: 'Built for teams who want to move faster, with less effort and more insight.',
        primary: ['#contact', '{{cta_text}}'], secondary: ['#features', 'See features'],
        card: { label: 'Trusted worldwide', title: 'Trusted worldwide', facts: [
          ['👥', '{{stat_users}}', 'Active users'],
          ['🌍', '{{stat_countries}}', 'Countries'],
          ['⚡', '{{stat_uptime}}', 'Uptime'],
        ] } }),
      section('features', '', cards([
        ['⚡', '{{feat1_title}}', '{{feat1_desc}}'],
        ['🔒', '{{feat2_title}}', '{{feat2_desc}}'],
        ['📊', '{{feat3_title}}', '{{feat3_desc}}'],
        ['🤝', '{{feat4_title}}', '{{feat4_desc}}'],
      ]), 'Features', 'Everything you need, nothing you don\'t'),
      section('how', 'alt', cards([
        ['1️⃣', 'Sign up', 'Create your account in under a minute. No card needed.'],
        ['2️⃣', 'Connect', 'Invite your team and connect the tools you already use.'],
        ['3️⃣', 'Grow', 'Track results on one dashboard and improve every week.'],
      ]), 'How it works', 'Up and running in minutes'),
      section('pricing', '', plans([
        ['Starter', 'Free', 'forever', ['Up to 3 users', 'Core features', 'Community support'], false],
        ['Growth', '$19', '/ user / month', ['Unlimited users', 'All features', 'Priority support'], true],
        ['Enterprise', 'Custom', '', ['Dedicated manager', 'Custom integrations', 'Uptime guarantee'], false],
      ]), 'Pricing', 'Plans that grow with you'),
      section('faq', 'alt', faq([
        ['Is there a free trial?', 'Yes. The Starter plan is free forever, and paid plans come with a 14-day trial.'],
        ['Is my data secure?', 'All data is encrypted in transit and at rest, and backed up daily.'],
        ['Can I cancel anytime?', 'Yes. There are no long-term contracts.'],
      ]), 'FAQ', 'Frequently asked questions'),
      band('Ready to get started?', 'Join {{stat_users}} people already using {{company_name}}.', ['#contact', '{{cta_text}}']),
    ],
    contact: { email: '{{email}}', title: 'Talk to our team', lead: 'Questions, demos or partnerships: we reply within one business day.',
      formTitle: 'Get in touch', subject: 'Website enquiry', button: 'Send message' },
    footerAbout: '{{tagline}}',
  },
  {
    id: 'ngo', name: '{{org_name}}', icon: '🤝', navCta: 'Donate',
    title: '{{org_name}} — {{tagline}}', description: '{{mission}}',
    palette: { primary: '#166534', dark: '#14532d', accent: '#ea580c', soft: '#dcfce7' },
    nav: [['mission', 'Mission'], ['programs', 'Programs'], ['impact', 'Impact'], ['faq', 'Get involved']],
    sections: [
      hero({ eyebrow: 'Together we can', title: '{{tagline}}', lead: '{{mission}}',
        primary: ['#contact', '{{donate_text}}'], secondary: ['#programs', 'Our programs'],
        card: { label: 'Our impact', title: 'Our impact so far', facts: [
          ['💚', '{{impact1_num}}', '{{impact1_label}}'],
          ['🌍', '{{impact2_num}}', '{{impact2_label}}'],
          ['🤲', '{{impact3_num}}', '{{impact3_label}}'],
        ] } }),
      split('mission', '', 'Our mission', '{{mission_title}}', '{{mission}}',
        ['Community-led programs', 'Transparent use of every donation', 'Lasting, measurable change'], '🌱'),
      section('programs', 'alt', cards([
        ['📚', '{{prog1_name}}', '{{prog1_desc}}'],
        ['💧', '{{prog2_name}}', '{{prog2_desc}}'],
        ['❤️', '{{prog3_name}}', '{{prog3_desc}}'],
      ]), 'Programs', 'What we do'),
      `<div id="impact">${stats([['{{impact1_num}}', '{{impact1_label}}'], ['{{impact2_num}}', '{{impact2_label}}'], ['{{impact3_num}}', '{{impact3_label}}']])}</div>`,
      section('faq', '', faq([
        ['How is my donation used?', 'Most of every donation goes directly to our programs. We publish a yearly report of our spending.'],
        ['Can I volunteer?', 'Yes. Send us a message with your skills and availability.'],
        ['Can organisations partner with you?', 'We welcome partnerships with schools, businesses and other NGOs.'],
      ]), 'Get involved', 'Ways to help'),
      band('Every contribution counts', 'Your support changes lives in our community.', ['#contact', '{{donate_text}}']),
    ],
    contact: { address: '{{address}}', phone: '{{phone}}', email: '{{email}}', title: 'Support our work', lead: 'Donate, volunteer or partner with us.',
      formTitle: 'Get involved', subject: 'Support enquiry', button: 'Send message', prefill: 'I would like to (donate / volunteer / partner):' },
    footerAbout: '{{tagline}}',
  },
  {
    id: 'portfolio', name: '{{name}}', icon: '✦', navCta: 'Hire me',
    title: '{{name}} — {{title}}', description: '{{about}}',
    palette: { primary: '#0f172a', dark: '#020617', accent: '#8b5cf6', soft: '#ede9fe' },
    nav: [['about', 'About'], ['skills', 'Skills'], ['work', 'Work'], ['reviews', 'Kind words']],
    sections: [
      hero({ eyebrow: '{{title}}', title: 'Hi, I\'m {{name}}', lead: '{{about}}',
        primary: ['#work', 'See my work'], secondary: ['#contact', 'Get in touch'],
        card: { label: 'Quick facts', title: 'Quick facts', facts: [
          ['📍', 'Based in', '{{location}}'],
          ['💼', 'Role', '{{title}}'],
          ['✅', 'Available', 'For freelance and full-time work'],
        ] } }),
      split('about', '', 'About me', 'What I do', '{{about}}',
        ['Clear communication', 'Deadlines met', 'Work that solves real problems'], '👩🏾‍💻'),
      section('skills', 'alt', `<ul class="checks" style="display:flex;flex-wrap:wrap;gap:12px;justify-content:center">
      ${[1, 2, 3, 4, 5].map((i) => `<li class="price-tag" style="margin:0">{{skill${i}}}</li>`).join('\n      ')}
    </ul>`, 'Skills', 'Skills and tools'),
      section('work', '', cards([
        ['🎨', '{{project1_name}}', '{{project1_desc}}'],
        ['📱', '{{project2_name}}', '{{project2_desc}}'],
        ['🌐', '{{project3_name}}', '{{project3_desc}}'],
      ]), 'Work', 'Selected projects'),
      section('reviews', 'alt', quotes([
        ['Delivered ahead of schedule and the result exceeded our expectations.', 'Project client'],
        ['Thoughtful, creative and a pleasure to work with.', 'Team lead'],
        ['Turned our rough idea into something we are proud of.', 'Start-up founder'],
      ]), 'Kind words', 'What people say'),
    ],
    contact: { address: '{{location}}', phone: '{{phone}}', email: '{{email}}', title: 'Let\'s work together', lead: 'Have a project in mind? I would love to hear about it.',
      formTitle: 'Tell me about your project', subject: 'Project enquiry', button: 'Send message' },
    footerAbout: '{{title}}',
  },
  {
    id: 'school', name: '{{school_name}}', icon: '🎓', navCta: 'Apply now',
    title: '{{school_name}} — {{motto}}', description: '{{description}}',
    palette: { primary: '#1d4ed8', dark: '#1e3a8a', accent: '#f59e0b', soft: '#dbeafe' },
    nav: [['about', 'About'], ['academics', 'Academics'], ['life', 'Student life'], ['admissions', 'Admissions']],
    sections: [
      hero({ eyebrow: 'Admissions open', title: '{{motto}}', lead: '{{description}}',
        primary: ['#admissions', 'How to apply'], secondary: ['#contact', 'Book a school visit'],
        card: { label: 'School at a glance', title: 'At a glance', facts: [
          ['👩‍🎓', '{{students}}', 'Students'],
          ['👨‍🏫', '{{teachers}}', 'Qualified teachers'],
          ['🏆', '{{pass_rate}}', 'National exam pass rate'],
        ] } }),
      stats([['{{students}}', 'Students'], ['{{teachers}}', 'Teachers'], ['{{pass_rate}}', 'Pass rate'], ['{{years}}', 'Years of excellence']]),
      split('about', '', 'About us', 'Nurturing tomorrow\'s leaders', '{{description}}',
        ['Experienced, caring teachers', 'Strong results in national exams', 'Safe, disciplined environment'], '🏫'),
      section('academics', 'alt', cards([
        ['🔬', 'Sciences', 'Biology, Chemistry and Physics with practical laboratory work.'],
        ['📐', 'Mathematics', 'From core skills to advanced problem solving.'],
        ['📚', 'Languages & humanities', 'English, Literature, History, Geography and more.'],
        ['💻', 'ICT', 'Digital skills, coding and computer studies.'],
      ]), 'Academics', 'A broad, balanced curriculum', 'Following the national curriculum from S1 to S6.'),
      section('life', '', gallery([['⚽', 'Sports'], ['🎭', 'Music, dance & drama'], ['🧪', 'Science club'], ['🌳', 'Environment club']]), 'Student life', 'Beyond the classroom'),
      section('admissions', 'alt', faq([
        ['How do I apply?', 'Collect an application form from the school office or contact us below. Bring recent report cards and a birth certificate.'],
        ['When does the term start?', 'Contact the school office for this year\'s term dates and interview days.'],
        ['Do you offer boarding?', 'Ask the admissions office about boarding places and fees.'],
      ]), 'Admissions', 'Joining our school'),
    ],
    contact: { address: '{{address}}', phone: '{{phone}}', email: '{{email}}', title: 'Visit or contact the school', lead: 'The school office is open Monday to Friday, 8:00 AM to 5:00 PM.',
      formTitle: 'Admissions enquiry', subject: 'Admissions enquiry', button: 'Send enquiry', prefill: 'Student name:\nClass applying for:\nQuestion:' },
    footerAbout: '{{motto}}',
  },
];

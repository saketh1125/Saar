import '../models/models.dart';

/// Bundled OSM-seeded Varanasi POIs. This is the Phase 0–5 VPD seed (~the
/// major ghats, prominent temples, famous food spots and practical nodes).
/// It lets the map render meaningful markers offline; the full ~1400-entry
/// extraction is the separately-flagged future project.
///
/// Coordinates are approximate community-map centres. The crawler worker
/// refreshes these from Overpass weekly server-side (see firebase/ crawlers).
const kSeedPois = <Poi>[
  // ── Major ghats (Ganga front, north → south) ──────────────────────────
  Poi(id: 'vpd_ghat_assi', name: 'Assi Ghat', category: PoiCategory.ghat, lat: 25.2833, lng: 83.0063,
    accessibility: 'Low', summary: 'Southernmost major ghat; morning Subah-e-Banaras aarti & yoga.',
    aliases: ['Assi'], sources: ['osm', 'wikipedia'], confidence: 0.99),
  Poi(id: 'vpd_ghat_dashashwamedh', name: 'Dashashwamedh Ghat', category: PoiCategory.ghat, lat: 25.3065, lng: 83.0107,
    accessibility: 'Low', summary: 'The main ghat; grand evening Ganga Aarti at ~6:45 PM.',
    aliases: ['Dasaswamedha', 'main ghat', 'aarti ghat'], sources: ['osm', 'wikipedia'], confidence: 0.99),
  Poi(id: 'vpd_ghat_manikarnika', name: 'Manikarnika Ghat', category: PoiCategory.ghat, lat: 25.3105, lng: 83.0130,
    accessibility: 'Medium', summary: 'Primary cremation ghat. Be respectful; watch for wood-donation scams.',
    aliases: ['Manikarnika'], sources: ['osm', 'wikipedia'], confidence: 0.99),
  Poi(id: 'vpd_ghat_harishchandra', name: 'Harishchandra Ghat', category: PoiCategory.ghat, lat: 25.3145, lng: 83.0150,
    accessibility: 'Medium', summary: 'Secondary cremation ghat, south of Manikarnika.'),
  Poi(id: 'vpd_ghat_scindia', name: 'Scindia Ghat', category: PoiCategory.ghat, lat: 25.3115, lng: 83.0135,
    accessibility: 'Medium'),
  Poi(id: 'vpd_ghat_dattatreya', name: 'Dattatreya Ghat', category: PoiCategory.ghat, lat: 25.3160, lng: 83.0160,
    accessibility: 'Medium'),
  Poi(id: 'vpd_ghat_manchakamika', name: 'Man Mandir Ghat', category: PoiCategory.ghat, lat: 25.3072, lng: 83.0109,
    accessibility: 'Low', summary: 'Home to Jai Singh II observatory.'),
  Poi(id: 'vpd_ghat_lalita', name: 'Lalita Ghat', category: PoiCategory.ghat, lat: 25.3085, lng: 83.0120,
    accessibility: 'Low'),
  Poi(id: 'vpd_ghat_panchaganga', name: 'Panchganga Ghat', category: PoiCategory.ghat, lat: 25.3180, lng: 83.0170,
    accessibility: 'Medium', summary: 'Where five mythic rivers meet; Alamgir Mosque towers above.'),
  Poi(id: 'vpd_ghat_raj', name: 'Raj Ghat', category: PoiCategory.ghat, lat: 25.3300, lng: 83.0200,
    accessibility: 'Low', summary: 'Northern entry; quieter alternative to the main ghats.'),
  Poi(id: 'vpd_ghat_tulsi', name: 'Tulsi Ghat', category: PoiCategory.ghat, lat: 25.2860, lng: 83.0070,
    accessibility: 'Low', summary: 'Named after poet-saint Tulsidas.'),

  // ── Prominent temples ─────────────────────────────────────────────────
  Poi(id: 'vpd_temple_vishwanath', name: 'Kashi Vishwanath Temple', category: PoiCategory.temple,
    lat: 25.3106, lng: 83.0101, summary: 'One of the 12 Jyotirlingas; the spiritual centre of Kashi.',
    aliases: ['Vishwanath', 'Golden Temple', 'KVT'], sources: ['osm', 'wikipedia'], confidence: 0.99),
  Poi(id: 'vpd_temple_annapurna', name: 'Annapurna Devi Temple', category: PoiCategory.temple,
    lat: 25.3108, lng: 83.0100, summary: 'Goddess of food; adjacent to Kashi Vishwanath.'),
  Poi(id: 'vpd_temple_kaal_bhairav', name: 'Kaal Bhairav Temple', category: PoiCategory.temple,
    lat: 25.3120, lng: 83.0095, summary: 'The kotwal (protector) deity of Kashi.'),
  Poi(id: 'vpd_temple_durga', name: 'Durga Temple', category: PoiCategory.temple,
    lat: 25.2870, lng: 83.0095, summary: 'Red temple with a nagara shikhara, near Durga Kund.'),
  Poi(id: 'vpd_temple_tulsi_manas', name: 'Tulsi Manas Mandir', category: PoiCategory.temple,
    lat: 25.2858, lng: 83.0098, summary: 'Wall murals of Tulsidas\'s Ramcharitmanas.'),
  Poi(id: 'vpd_temple_sankat_mochan', name: 'Sankat Mochan Hanuman Temple', category: PoiCategory.temple,
    lat: 25.2800, lng: 83.0050, summary: 'Hanuman temple founded by Tulsidas; famous for Sunday prasad.'),
  Poi(id: 'vpd_temple_bharat_mata', name: 'Bharat Mata Temple', category: PoiCategory.temple,
    lat: 25.2920, lng: 83.0120, summary: 'Relief map of undivided India in marble.'),
  Poi(id: 'vpd_temple_new_vishwanath', name: 'Birla (New Vishwanath) Temple', category: PoiCategory.temple,
    lat: 25.2780, lng: 83.0000, summary: 'Open campus replica at BHU.'),

  // ── Food spots ────────────────────────────────────────────────────────
  Poi(id: 'vpd_food_blue_lassi', name: 'Blue Lassi Shop', category: PoiCategory.food,
    lat: 25.3115, lng: 83.0102, summary: 'Iconic thick lassi near Manikarnika, 80+ flavours.'),
  Poi(id: 'vpd_food_ram_bhandar', name: 'Ram Bhandar', category: PoiCategory.food,
    lat: 25.3112, lng: 83.0105, summary: 'Famous kachori-sabzi breakfast, Vishwanath Gali.'),
  Poi(id: 'vpd_food_deena_chat', name: 'Deena Chat Bhandar', category: PoiCategory.food,
    lat: 25.3095, lng: 83.0125, summary: 'Beloved chaat house on Kachauri Gali.'),
  Poi(id: 'vpd_food_pappu_chai', name: 'Pappu Chai Stall', category: PoiCategory.food,
    lat: 25.2834, lng: 83.0064, summary: 'Kullhad chai behind Assi Ghat.'),
  Poi(id: 'vpd_food_baati_chokha', name: 'Baati Chokha Stall', category: PoiCategory.food,
    lat: 25.3100, lng: 83.0110, summary: 'Rustic UP baati-chokha near Godowlia.'),
  Poi(id: 'vpd_food_kachori_subhash', name: 'Kachori Sabzi Subhash', category: PoiCategory.food,
    lat: 25.3130, lng: 83.0120, summary: 'Heavy local breakfast queue, Bangali Tola.'),

  // ── Practical / safety nodes ──────────────────────────────────────────
  Poi(id: 'vpd_safety_godowlia', name: 'Godowlia Crossing', category: PoiCategory.safety,
    lat: 25.3120, lng: 83.0115, summary: 'Main road hub; nearest vehicle access from the ghats.'),
  Poi(id: 'vpd_safety_das_apex', name: 'Das Memorial Hospital', category: PoiCategory.safety,
    lat: 25.2970, lng: 83.0100, summary: 'Multi-specialty hospital.'),
  Poi(id: 'vpd_safety_leper_hospital', name: 'Sir Sundar Lal Hospital (BHU)', category: PoiCategory.safety,
    lat: 25.2760, lng: 82.9980, summary: 'University hospital, south of the city.'),
  Poi(id: 'vpd_safety_police_dash', name: 'Dashashwamedh Police Outpost', category: PoiCategory.safety,
    lat: 25.3068, lng: 83.0108, summary: 'Tourist police outpost near the main ghat.'),

  // ── Water & hygiene nodes (verified, see design §4.10) ────────────────
  Poi(id: 'vpd_water_assi', name: 'RO Water — Assi Ghat', category: PoiCategory.water,
    lat: 25.2836, lng: 83.0065, summary: 'Jal Board RO kiosk; tested clean.'),
  Poi(id: 'vpd_water_dash', name: 'RO Water — Dashashwamedh', category: PoiCategory.water,
    lat: 25.3067, lng: 83.0106),
  Poi(id: 'vpd_water_godowlia', name: 'RO Water — Godowlia', category: PoiCategory.water,
    lat: 25.3119, lng: 83.0114),
  Poi(id: 'vpd_toilet_assi', name: 'Public Toilet — Assi Ghat', category: PoiCategory.toilet,
    lat: 25.2837, lng: 83.0066, summary: 'Cleanliness ★★★ (community-maintained).'),
  Poi(id: 'vpd_toilet_dash', name: 'Public Toilet — Dashashwamedh', category: PoiCategory.toilet,
    lat: 25.3066, lng: 83.0105, summary: 'Cleanliness ★★'),

  // ── Viewpoints / markets ──────────────────────────────────────────────
  Poi(id: 'vpd_view_river_bridge', name: 'Malviya Bridge Viewpoint', category: PoiCategory.view,
    lat: 25.2620, lng: 82.9950, summary: 'Panoramic river-curve vista at sunrise.'),
  Poi(id: 'vpd_market_godowlia', name: 'Godowlia Market', category: PoiCategory.market,
    lat: 25.3121, lng: 83.0116, summary: 'Silk sarees, brass, souvenirs. Bargain hard.'),
  Poi(id: 'vpd_market_vishwanath_gali', name: 'Vishwanath Gali', category: PoiCategory.market,
    lat: 25.3109, lng: 83.0103, summary: 'Pilgrim supplies, prasad, flowers on the temple approach.'),
  Poi(id: 'vpd_market_thatheri_bazaar', name: 'Thatheri Bazaar', category: PoiCategory.market,
    lat: 25.3145, lng: 83.0125, summary: 'Brassware and copper utensils wholesale.'),
];

/// Approximate "main road" nodes — vehicle-accessible crossings near the
/// ghats. Used by the Escape-Route FAB to route a user out of dense galis.
const kMainRoadNodes = <Poi>[
  Poi(id: 'mainroad_godowlia', name: 'Godowlia Crossing', category: PoiCategory.safety,
    lat: 25.3120, lng: 83.0115, summary: 'Nearest main road from Vishwanath/Dashashwamedh.'),
  Poi(id: 'mainroad_dasashwamedh', name: 'Dashashwamedh Road Head', category: PoiCategory.safety,
    lat: 25.3065, lng: 83.0095),
  Poi(id: 'mainroad_assi', name: 'Assi Road Junction', category: PoiCategory.safety,
    lat: 25.2850, lng: 83.0050),
  Poi(id: 'mainroad_sonarpura', name: 'Sonarpura Crossing', category: PoiCategory.safety,
    lat: 25.3180, lng: 83.0120),
];

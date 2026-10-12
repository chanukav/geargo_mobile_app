const https = require('https');
const { execSync } = require('child_process');

function getAccessToken() {
  try {
    return execSync('gcloud auth print-access-token', { stdio: ['pipe', 'pipe', 'ignore'] }).toString().trim();
  } catch (err) {
    console.error('Failed to get gcloud access token. Ensure gcloud CLI is authenticated.');
    process.exit(1);
  }
}

const token = getAccessToken();
const projectId = 'geargo-e0035';
const baseUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;

function writeDocument(collection, docId, fields) {
  return new Promise((resolve, reject) => {
    const url = `${baseUrl}/${collection}/${docId}`;
    const payload = JSON.stringify({ fields });

    const req = https.request(url, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload),
      },
    }, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`[${res.statusCode}] ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

function stringField(v) { return { stringValue: String(v || '') }; }
function doubleField(v) { return { doubleValue: Number(v) }; }
function intField(v) { return { integerValue: String(Math.round(v)) }; }
function boolField(v) { return { booleanValue: Boolean(v) }; }
function timestampField(v) { return { timestampValue: (v instanceof Date ? v : new Date()).toISOString() }; }

const sampleEquipment = [
  {
    id: 'gear_specialized_stumpjumper',
    ownerId: 'owner_default',
    name: 'Specialized Stumpjumper EVO Comp Bike',
    category: 'mountain_bikes',
    description: 'Mechanically perfect, freshly tuned, cleaned after every rental. FOX Float 36 Rhythm fork, SRAM NX Eagle 12-speed drivetrain with hydraulic 4-piston disc brakes.',
    price: 45.0,
    availability: true,
    image: 'https://images.unsplash.com/photo-1576435728678-68d0fbf94e91?auto=format&fit=crop&w=1200&q=80',
    condition: 'Excellent / Like New',
    location: 'Colombo 07, Cinnamon Gardens',
    rating: 4.9,
    reviewsCount: 3,
  },
  {
    id: 'gear_giro_manifest',
    ownerId: 'owner_default',
    name: 'Giro Manifest Spheric Helmet',
    category: 'mountain_bikes',
    description: 'MIPS Spheric technology trail helmet, size Medium. Superior ventilation and impact management, thoroughly sanitized after every ride.',
    price: 8.0,
    availability: true,
    image: 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&w=1200&q=80',
    condition: 'Like New',
    location: 'Colombo, Sri Lanka',
    rating: 4.9,
    reviewsCount: 2,
  },
  {
    id: 'gear_north_face_tent',
    ownerId: 'owner_default',
    name: 'The North Face Wawona Tent',
    category: 'camping',
    description: 'Spacious 6-person car camping tent with massive vestibule, hybrid double-wall construction, and color-coded poles for 10-minute setup.',
    price: 28.0,
    availability: true,
    image: 'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?auto=format&fit=crop&w=1200&q=80',
    condition: 'Excellent',
    location: 'Kandy, Sri Lanka',
    rating: 4.7,
    reviewsCount: 2,
  },
  {
    id: 'gear_babolat_pure_drive',
    ownerId: 'owner_default',
    name: 'Babolat Pure Drive Tennis Racket',
    category: 'fitness',
    description: 'Legendary power and spin racket with fresh Babolat RPM Blast 16G strings at 54 lbs tension. 4 3/8 grip size with new overgrip.',
    price: 15.0,
    availability: true,
    image: 'https://images.unsplash.com/photo-1622279457486-62dcc4a431d6?auto=format&fit=crop&w=1200&q=80',
    condition: 'Very Good',
    location: 'Colombo, Sri Lanka',
    rating: 4.6,
    reviewsCount: 1,
  },
  {
    id: 'gear_trekking_poles',
    ownerId: 'owner_default',
    name: 'Black Diamond Trekking Poles',
    category: 'camping',
    description: 'Trail Pro shock-absorbing carbon fiber hiking poles with FlickLock Pro adjustments and natural cork grips.',
    price: 12.0,
    availability: true,
    image: 'https://images.unsplash.com/photo-1551632811-561732d1e306?auto=format&fit=crop&w=1200&q=80',
    condition: 'Excellent',
    location: 'Ella, Sri Lanka',
    rating: 4.8,
    reviewsCount: 1,
  },
  {
    id: 'gear_specialized_rockhopper_comp',
    ownerId: 'owner_default',
    name: 'Specialized Rockhopper Comp',
    category: 'mountain_bikes',
    description: 'Lightweight A1 Premium aluminum hardtail mountain bike with Shimano Deore 1x10 drivetrain and SR Suntour XCM suspension fork.',
    price: 32.0,
    availability: true,
    image: 'https://images.unsplash.com/photo-1485965120184-e220f721d03e?auto=format&fit=crop&w=1200&q=80',
    condition: 'Excellent',
    location: 'Galle, Sri Lanka',
    rating: 4.9,
    reviewsCount: 1,
  },
  {
    id: 'gear_torq_surfboard',
    ownerId: 'user_shop_apex',
    name: 'Torq Mod Fun 7\'2" Surfboard',
    category: 'surfing',
    description: 'Versatile epoxy funboard shaped for mid-length wave cruising in Mirissa and Weligama. Includes thruster fins and 7ft leash.',
    price: 35.0,
    availability: true,
    image: 'https://images.unsplash.com/photo-1502680390469-be75c86b636f?auto=format&fit=crop&w=1200&q=80',
    condition: 'Excellent',
    location: 'Mirissa, Sri Lanka',
    rating: 5.0,
    reviewsCount: 2,
  },
  {
    id: 'gear_ss_ton_cricket_bat',
    ownerId: 'owner_default',
    name: 'SS Ton Professional English Willow Bat',
    category: 'cricket',
    description: 'Handcrafted Grade 1 English Willow cricket bat, professionally knocked-in with anti-scuff sheet and toe guard. Superb balance.',
    price: 20.0,
    availability: true,
    image: 'https://images.unsplash.com/photo-1531415074868-036b107e775a?auto=format&fit=crop&w=1200&q=80',
    condition: 'Like New',
    location: 'Colombo 05 (Havelock), Sri Lanka',
    rating: 4.8,
    reviewsCount: 1,
  },
  {
    id: 'gear_yonex_astrox_badminton',
    ownerId: 'user_shop_apex',
    name: 'Yonex Astrox 88D Pro Badminton Racket',
    category: 'badminton',
    description: 'Head-heavy offensive doubles racket, strung with Yonex BG80 at 26 lbs tension with cushioned overgrip.',
    price: 15.0,
    availability: true,
    image: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=1200&q=80',
    condition: 'Like New',
    location: 'Negombo, Sri Lanka',
    rating: 4.9,
    reviewsCount: 1,
  },
  {
    id: 'gear_adidas_match_ball',
    ownerId: 'owner_default',
    name: 'Adidas FIFA Pro Official Match Ball',
    category: 'football',
    description: 'Thermally bonded seamless construction for predictable flight trajectory and low water uptake on grass and turf pitches.',
    price: 10.0,
    availability: true,
    image: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?auto=format&fit=crop&w=1200&q=80',
    condition: 'Brand New',
    location: 'Colombo 07, Sri Lanka',
    rating: 5.0,
    reviewsCount: 1,
  },
  {
    id: 'gear_deuter_aircontact_backpack',
    ownerId: 'user_shop_apex',
    name: 'Deuter Aircontact Lite 50+10L Backpack',
    category: 'hiking',
    description: 'Ergonomic trekking backpack with adjustable back length, rain cover, and trekking pole loops. Perfect for Horton Plains or Ella hikes.',
    price: 16.0,
    availability: true,
    image: 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=1200&q=80',
    condition: 'Like New',
    location: 'Ella, Sri Lanka',
    rating: 4.9,
    reviewsCount: 1,
  },
  {
    id: 'gear_kookaburra_cricket_kit',
    ownerId: 'user_shop_apex',
    name: 'Kookaburra Kahuna Complete Kit Bag',
    category: 'cricket',
    description: 'Full protective match kit including batting pads, gloves, thigh guard, inner pads, and certified cricket helmet.',
    price: 38.0,
    availability: true,
    image: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=1200&q=80',
    condition: 'Very Good',
    location: 'Colombo 08 (Borella), Sri Lanka',
    rating: 4.8,
    reviewsCount: 1,
  },
];

const sampleReviews = [
  {
    id: 'seed_review_stumpjumper_01',
    equipmentId: 'gear_specialized_stumpjumper',
    ownerId: 'owner_default',
    authorId: 'user_sarah_k',
    authorName: 'Sarah K.',
    rating: 5,
    comment: 'Perfect bike for the trail loops! Marcus was great at setup. Highly recommend.',
    equipmentName: 'Specialized Stumpjumper EVO Comp Bike',
  },
  {
    id: 'seed_review_stumpjumper_02',
    equipmentId: 'gear_specialized_stumpjumper',
    ownerId: 'owner_default',
    authorId: 'user_david_m',
    authorName: 'David M.',
    rating: 5,
    comment: 'Super smooth suspension and well maintained. Marcus even gave trail recommendations!',
    equipmentName: 'Specialized Stumpjumper EVO Comp Bike',
  },
  {
    id: 'seed_review_stumpjumper_03',
    equipmentId: 'gear_specialized_stumpjumper',
    ownerId: 'owner_default',
    authorId: 'user_liam_w',
    authorName: 'Liam W.',
    rating: 5,
    comment: 'Immaculate condition, hydraulic disc brakes gripped flawlessly on downhill descents.',
    equipmentName: 'Specialized Stumpjumper EVO Comp Bike',
  },
  {
    id: 'seed_review_giro_01',
    equipmentId: 'gear_giro_manifest',
    ownerId: 'owner_default',
    authorId: 'user_alex_t',
    authorName: 'Alex T.',
    rating: 5,
    comment: 'High quality helmet, fits true to size and sanitized before handoff.',
    equipmentName: 'Giro Manifest Spheric Helmet',
  },
  {
    id: 'seed_review_giro_02',
    equipmentId: 'gear_giro_manifest',
    ownerId: 'owner_default',
    authorId: 'user_chris_b',
    authorName: 'Chris B.',
    rating: 5,
    comment: 'Very lightweight with MIPS protection. Friendly pickup.',
    equipmentName: 'Giro Manifest Spheric Helmet',
  },
  {
    id: 'seed_review_tent_01',
    equipmentId: 'gear_north_face_tent',
    ownerId: 'owner_default',
    authorId: 'user_jessica_p',
    authorName: 'Jessica P.',
    rating: 4,
    comment: 'Spacious and easy to assemble tent. All poles and pegs accounted for.',
    equipmentName: 'The North Face Wawona Tent',
  },
  {
    id: 'seed_review_tent_02',
    equipmentId: 'gear_north_face_tent',
    ownerId: 'owner_default',
    authorId: 'user_mark_d',
    authorName: 'Mark D.',
    rating: 5,
    comment: 'Waterproof held up great in rain. Highly recommended.',
    equipmentName: 'The North Face Wawona Tent',
  },
  {
    id: 'seed_review_babolat_01',
    equipmentId: 'gear_babolat_pure_drive',
    ownerId: 'owner_default',
    authorId: 'user_michael_c',
    authorName: 'Michael C.',
    rating: 5,
    comment: 'Strings in great tension, great control on court. Host was very communicative.',
    equipmentName: 'Babolat Pure Drive Tennis Racket',
  },
  {
    id: 'seed_review_poles_01',
    equipmentId: 'gear_trekking_poles',
    ownerId: 'owner_default',
    authorId: 'user_hannah_g',
    authorName: 'Hannah G.',
    rating: 5,
    comment: 'Sturdy carbon poles, saved my knees on the steep descent.',
    equipmentName: 'Black Diamond Trekking Poles',
  },
  {
    id: 'seed_review_rockhopper_01',
    equipmentId: 'gear_specialized_rockhopper_comp',
    ownerId: 'owner_default',
    authorId: 'user_ryan_b',
    authorName: 'Ryan B.',
    rating: 5,
    comment: 'Great hardtail for local trail loops. Brakes and gear shifts were flawless.',
    equipmentName: 'Specialized Rockhopper Comp',
  },
  {
    id: 'seed_review_surfboard_01',
    equipmentId: 'gear_torq_surfboard',
    ownerId: 'user_shop_apex',
    authorId: 'user_tariq_a',
    authorName: 'Tariq A.',
    rating: 5,
    comment: 'Super fun board at Weligama bay! Responsive and buoyant, wax was fresh.',
    equipmentName: 'Torq Mod Fun 7\'2" Surfboard',
  },
  {
    id: 'seed_review_cricket_01',
    equipmentId: 'gear_ss_ton_cricket_bat',
    ownerId: 'owner_default',
    authorId: 'user_dinesh_p',
    authorName: 'Dinesh P.',
    rating: 5,
    comment: 'Incredible ping and balanced pickup! Made our weekend match in Colombo a blast.',
    equipmentName: 'SS Ton Professional English Willow Bat',
  },
];

const personas = [
  {
    uid: 'user_renter_maya',
    email: 'maya.chen@example.com',
    displayName: 'Maya Chen',
    photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    role: 'renter',
    phoneNumber: '+94 77 234 5678',
    bio: 'Avid weekend hiker, trail runner, and outdoor enthusiast.',
    address: 'Colombo 07, Sri Lanka',
    isVerified: true,
  },
  {
    uid: 'owner_default',
    email: 'marcus.vance@example.com',
    displayName: 'Marcus Vance',
    photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    role: 'owner',
    phoneNumber: '+94 71 345 6789',
    bio: 'Passionate mountain biker & gear collector. All equipment tuned before handover.',
    address: 'Kandy, Sri Lanka',
    businessName: 'Vance Trail Rentals',
    isVerified: true,
  },
  {
    uid: 'user_shop_apex',
    email: 'rentals@apexadventure.com',
    displayName: 'Apex Mountain Gear',
    photoUrl: 'https://images.unsplash.com/photo-1556742049-0a67e557224f?auto=format&fit=crop&w=400&q=80',
    role: 'commercialShop',
    phoneNumber: '+94 11 890 1234',
    bio: 'Commercial full-service rental depot offering fleet bikes, surfboards, and camping gear.',
    address: 'Nuwara Eliya, Sri Lanka',
    businessName: 'Apex Mountain Gear Commercial Depot',
    isVerified: true,
  },
  {
    uid: 'user_admin_elena',
    email: 'admin.elena@geargo.com',
    displayName: 'Elena Rostova',
    photoUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
    role: 'admin',
    phoneNumber: '+94 11 999 0001',
    bio: 'GearGo platform trust, safety, and operations administrator.',
    address: 'Colombo 03, Sri Lanka',
    businessName: 'GearGo Platform Operations',
    isVerified: true,
  },
];

async function seed() {
  console.log(`Starting Firestore Cloud seeding for project: ${projectId}...`);

  // 1. Seed Personas into users collection
  console.log('\n--- Seeding Users / Personas ---');
  for (const p of personas) {
    const fields = {
      uid: stringField(p.uid),
      email: stringField(p.email),
      display_name: stringField(p.displayName),
      photo_url: stringField(p.photoUrl),
      role: stringField(p.role),
      phone_number: stringField(p.phoneNumber),
      bio: stringField(p.bio),
      address: stringField(p.address),
      is_verified: boolField(p.isVerified),
      created_at: timestampField(new Date()),
      updated_at: timestampField(new Date()),
    };
    if (p.businessName) fields.business_name = stringField(p.businessName);

    await writeDocument('users', p.uid, fields);
    console.log(`✓ User persona seeded: ${p.displayName} (${p.uid}) [${p.role}]`);

    // Also sync owner_profile
    if (p.role === 'owner' || p.role === 'commercialShop') {
      const profileFields = {
        id: stringField(p.uid),
        user_id: stringField(p.uid),
        name: stringField(p.displayName),
        phone: stringField(p.phoneNumber),
        address: stringField(p.address),
        profile_image: stringField(p.photoUrl),
        business_name: stringField(p.businessName || `${p.displayName} Rentals`),
        bio: stringField(p.bio),
        is_verified: boolField(p.isVerified),
        created_at: timestampField(new Date()),
        updated_at: timestampField(new Date()),
      };
      await writeDocument('owner_profile', p.uid, profileFields);
      console.log(`  ✓ Owner profile seeded for: ${p.uid}`);
    }
  }

  // 2. Seed Equipment
  console.log('\n--- Seeding Equipment Catalog ---');
  for (const eq of sampleEquipment) {
    const fields = {
      name: stringField(eq.name),
      owner_id: stringField(eq.ownerId),
      category: stringField(eq.category),
      description: stringField(eq.description),
      price: doubleField(eq.price),
      availability: boolField(eq.availability),
      image: stringField(eq.image),
      condition: stringField(eq.condition),
      location: stringField(eq.location),
      rating: doubleField(eq.rating),
      reviews_count: intField(eq.reviewsCount),
      created_at: timestampField(new Date(Date.now() - 30 * 86400000)),
      updated_at: timestampField(new Date()),
    };

    await writeDocument('equipment', eq.id, fields);
    console.log(`✓ Equipment seeded: ${eq.name} (Rs. ${eq.price}/day in ${eq.location})`);
  }

  // 3. Seed Reviews
  console.log('\n--- Seeding 1-to-N Equipment Reviews ---');
  for (const rev of sampleReviews) {
    const fields = {
      equipment_id: stringField(rev.equipmentId),
      equipment_name: stringField(rev.equipmentName),
      owner_id: stringField(rev.ownerId),
      author_id: stringField(rev.authorId),
      author_name: stringField(rev.authorName),
      rating: intField(rev.rating),
      comment: stringField(rev.comment),
      created_at: timestampField(new Date(Date.now() - 5 * 86400000)),
    };

    await writeDocument('equipment_reviews', rev.id, fields);
    console.log(`✓ Review seeded: [${rev.rating}★] for ${rev.equipmentName} by ${rev.authorName}`);
  }

  console.log('\n=========================================');
  console.log('🎉 Successfully seeded Firestore Database!');
  console.log(`   - 4 User Personas in /users & /owner_profile`);
  console.log(`   - ${sampleEquipment.length} Equipment Items in /equipment`);
  console.log(`   - ${sampleReviews.length} Verified Reviews in /equipment_reviews`);
  console.log('=========================================\n');
}

seed().catch(err => {
  console.error('\n❌ Seeding failed:', err);
  process.exit(1);
});

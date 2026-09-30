import 'model/website_models.dart';

const _img = 'https://images.unsplash.com/photo-';
const _q = '?w=800&q=75&auto=format&fit=crop';

/// Static content for the customer website. Not connected to Supabase yet —
/// edit the lists below to change branches, categories and shoes.
class SafiData {
  SafiData._();

  static const brandName = 'Safi Shoes';
  static const tagline = 'Quality footwear for the whole family';
  static const phone = '+92 300 0000000';
  static const email = 'info@safishoes.pk';

  /// Where orders are sent on WhatsApp when a branch has no number of its own.
  static const whatsapp = '923000000000';

  static const logoImage = 'assets/images/safi.png';
  static const heroImage = '${_img}1549298916-b41d501d3772$_q';
  static const spotlightImage = '${_img}1614252235316-8c857d38b5f4$_q';

  // TODO: replace with the real branch names, addresses, numbers and map pins.
  static const branches = <ShopBranch>[
    ShopBranch(
      id: 'saddar',
      name: 'Safi Shoes — Saddar',
      area: 'Saddar',
      city: 'Karachi',
      address: 'Main Saddar Bazaar, Karachi',
      phone: '+92 300 0000001',
      whatsapp: '923000000001',
      hours: '11:00 AM – 11:00 PM',
      lat: 24.8546,
      lng: 67.0299,
    ),
    ShopBranch(
      id: 'tariq-road',
      name: 'Safi Shoes — Tariq Road',
      area: 'Tariq Road',
      city: 'Karachi',
      address: 'Tariq Road, PECHS Block 2, Karachi',
      phone: '+92 300 0000002',
      whatsapp: '923000000002',
      hours: '11:00 AM – 11:00 PM',
      lat: 24.8722,
      lng: 67.0625,
    ),
    ShopBranch(
      id: 'gulshan',
      name: 'Safi Shoes — Gulshan-e-Iqbal',
      area: 'Gulshan-e-Iqbal',
      city: 'Karachi',
      address: 'Block 13-C, Gulshan-e-Iqbal, Karachi',
      phone: '+92 300 0000003',
      whatsapp: '923000000003',
      hours: '11:00 AM – 11:00 PM',
      lat: 24.9206,
      lng: 67.0935,
    ),
    ShopBranch(
      id: 'north-nazimabad',
      name: 'Safi Shoes — North Nazimabad',
      area: 'North Nazimabad',
      city: 'Karachi',
      address: 'Block H, North Nazimabad, Karachi',
      phone: '+92 300 0000004',
      whatsapp: '923000000004',
      hours: '11:00 AM – 11:00 PM',
      lat: 24.9425,
      lng: 67.0356,
    ),
  ];

  static const categories = <ShoeCategory>[
    ShoeCategory(
      id: 'men-formal',
      name: "Men's Formal",
      tagline: 'Leather shoes for office & events',
      image: '${_img}1533867617858-e7b97e060509$_q',
    ),
    ShoeCategory(
      id: 'sneakers',
      name: 'Sneakers & Sports',
      tagline: 'Running, gym and everyday',
      image: '${_img}1542291026-7eec264c27ff$_q',
    ),
    ShoeCategory(
      id: 'ladies',
      name: 'Ladies Collection',
      tagline: 'Heels, pumps and sandals',
      image: '${_img}1543163521-1bf539c55dd2$_q',
    ),
    ShoeCategory(
      id: 'casual',
      name: 'Casual',
      tagline: 'Easy canvas and lifestyle pairs',
      image: '${_img}1525966222134-fcfa99b8ae77$_q',
    ),
    ShoeCategory(
      id: 'boots',
      name: 'Boots',
      tagline: 'Tough leather for every season',
      image: '${_img}1520639888713-7851133b1ed0$_q',
    ),
    ShoeCategory(
      id: 'sandals',
      name: 'Sandals & Chappal',
      tagline: 'Comfort for hot days',
      image: '${_img}1603487742131-4160ec999306$_q',
    ),
  ];

  static const _men = [39, 40, 41, 42, 43, 44];
  static const _ladies = [36, 37, 38, 39, 40, 41];

  static const shoes = <Shoe>[
    // Men's formal
    Shoe(
      id: 'mf-oxford-brown',
      name: 'Classic Oxford — Brown',
      categoryId: 'men-formal',
      price: 6500,
      oldPrice: 7800,
      sizes: _men,
      image: '${_img}1449505278894-297fdb3edbc1$_q',
      description: 'Genuine leather oxford with a cushioned insole — made for long office days.',
      isNew: true,
    ),
    Shoe(
      id: 'mf-monk-strap',
      name: 'Double Monk Strap',
      categoryId: 'men-formal',
      price: 7200,
      sizes: _men,
      image: '${_img}1533867617858-e7b97e060509$_q',
      description: 'Polished leather with twin buckles for weddings and events.',
    ),
    Shoe(
      id: 'mf-derby-tan',
      name: 'Tan Derby',
      categoryId: 'men-formal',
      price: 5900,
      sizes: _men,
      image: '${_img}1614252235316-8c857d38b5f4$_q',
      description: 'Soft tan leather derby with a durable rubber sole.',
    ),
    // Sneakers & sports
    Shoe(
      id: 'sn-runner-red',
      name: 'Flyknit Runner — Red',
      categoryId: 'sneakers',
      price: 8500,
      oldPrice: 9900,
      sizes: _men,
      image: '${_img}1542291026-7eec264c27ff$_q',
      description: 'Lightweight knit runner with a springy foam sole.',
      isNew: true,
    ),
    Shoe(
      id: 'sn-trainer-white',
      name: 'Street Trainer — White',
      categoryId: 'sneakers',
      price: 7400,
      sizes: _men,
      image: '${_img}1460353581641-37baddab0fa2$_q',
      description: 'Breathable mesh trainer for everyday wear.',
    ),
    Shoe(
      id: 'sn-gym-volt',
      name: 'Gym Trainer — Volt',
      categoryId: 'sneakers',
      price: 8900,
      sizes: _men,
      image: '${_img}1606107557195-0e29a4b5b4aa$_q',
      description: 'Stable base and grippy sole for workouts.',
      isNew: true,
    ),
    Shoe(
      id: 'sn-air-orange',
      name: 'Air Cushion — Orange',
      categoryId: 'sneakers',
      price: 9500,
      sizes: _men,
      image: '${_img}1514989940723-e8e51635b782$_q',
      description: 'Bold colourway with a visible air cushion heel.',
    ),
    Shoe(
      id: 'sn-leather-white',
      name: 'Leather Court — White',
      categoryId: 'sneakers',
      price: 6900,
      sizes: _men,
      image: '${_img}1608231387042-66d1773070a5$_q',
      description: 'Clean white leather court shoe that goes with everything.',
    ),
    Shoe(
      id: 'sn-black',
      name: 'Knit Runner — Black',
      categoryId: 'sneakers',
      price: 7800,
      sizes: _men,
      image: '${_img}1491553895911-0055eca6402d$_q',
      description: 'All-black knit runner, light and flexible.',
    ),
    // Ladies
    Shoe(
      id: 'la-pump-navy',
      name: 'Suede Pump — Navy',
      categoryId: 'ladies',
      price: 5400,
      sizes: _ladies,
      image: '${_img}1515347619252-60a4bf4fff4f$_q',
      description: 'Elegant suede pump with a comfortable 3-inch heel.',
      isNew: true,
    ),
    Shoe(
      id: 'la-floral-heel',
      name: 'Floral Stiletto',
      categoryId: 'ladies',
      price: 6200,
      oldPrice: 6900,
      sizes: _ladies,
      image: '${_img}1543163521-1bf539c55dd2$_q',
      description: 'Printed pointed-toe stiletto for parties.',
    ),
    Shoe(
      id: 'la-black-heel',
      name: 'Black Stiletto',
      categoryId: 'ladies',
      price: 5800,
      sizes: _ladies,
      image: '${_img}1554062614-6da4fa67725a$_q',
      description: 'The classic black heel every wardrobe needs.',
    ),
    Shoe(
      id: 'la-platform',
      name: 'Platform Sandal — Maroon',
      categoryId: 'ladies',
      price: 4600,
      sizes: _ladies,
      image: '${_img}1562273138-f46be4ebdf33$_q',
      description: 'Cross-strap platform sandal with a cork-look sole.',
    ),
    Shoe(
      id: 'la-sneaker-pink',
      name: 'Ladies Runner — Pink',
      categoryId: 'ladies',
      price: 6700,
      sizes: _ladies,
      image: '${_img}1551107696-a4b0c5a0d9a2$_q',
      description: 'Soft pink runner with extra cushioning.',
    ),
    Shoe(
      id: 'la-pastel',
      name: 'Pastel Court Sneaker',
      categoryId: 'ladies',
      price: 7100,
      sizes: _ladies,
      image: '${_img}1595950653106-6c9ebd614d3a$_q',
      description: 'Layered pastel sneaker with a chunky sole.',
    ),
    // Casual
    Shoe(
      id: 'ca-skate-maroon',
      name: 'Canvas Skate — Maroon',
      categoryId: 'casual',
      price: 3900,
      oldPrice: 4500,
      sizes: _men,
      image: '${_img}1525966222134-fcfa99b8ae77$_q',
      description: 'Classic low-top canvas shoe with a side stripe.',
    ),
    Shoe(
      id: 'ca-hi-top',
      name: 'Canvas Hi-Top — Cream',
      categoryId: 'casual',
      price: 4200,
      sizes: _men,
      image: '${_img}1621665421558-831f91fd0500$_q',
      description: 'Cream hi-top canvas with a rubber toe cap.',
    ),
    Shoe(
      id: 'ca-chunky',
      name: 'Chunky Lifestyle Sneaker',
      categoryId: 'casual',
      price: 7600,
      sizes: _men,
      image: '${_img}1560769629-975ec94e6a86$_q',
      description: 'Multi-panel lifestyle sneaker with a bold sole.',
      isNew: true,
    ),
    Shoe(
      id: 'ca-wheat',
      name: 'Leather Low — Wheat',
      categoryId: 'casual',
      price: 8200,
      sizes: _men,
      image: '${_img}1549298916-b41d501d3772$_q',
      description: 'Wheat leather low-top with a crisp white sole.',
    ),
    // Boots
    Shoe(
      id: 'bo-work',
      name: 'Leather Work Boot',
      categoryId: 'boots',
      price: 9800,
      sizes: _men,
      image: '${_img}1520639888713-7851133b1ed0$_q',
      description: 'Rugged lace-up boot with a thick lug sole.',
    ),
    Shoe(
      id: 'bo-hiker',
      name: 'Suede Hiker Boot',
      categoryId: 'boots',
      price: 10500,
      oldPrice: 11900,
      sizes: _men,
      image: '${_img}1605812860427-4024433a70fd$_q',
      description: 'Water-resistant suede boot for travel and trekking.',
    ),
    // Sandals & chappal
    Shoe(
      id: 'sa-cork',
      name: 'Cork Two-Strap Sandal',
      categoryId: 'sandals',
      price: 3200,
      sizes: [38, 39, 40, 41, 42, 43, 44],
      image: '${_img}1603487742131-4160ec999306$_q',
      description: 'Contoured cork footbed with adjustable buckles.',
      isNew: true,
    ),
    Shoe(
      id: 'sa-cross',
      name: 'Cross-Strap Sandal',
      categoryId: 'sandals',
      price: 2900,
      sizes: _ladies,
      image: '${_img}1562273138-f46be4ebdf33$_q',
      description: 'Light and comfortable for everyday summer wear.',
    ),
  ];

  static List<Shoe> byCategory(String id) => shoes.where((s) => s.categoryId == id).toList();

  static ShoeCategory? category(String? id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  static ShopBranch? branch(String? id) {
    for (final b in branches) {
      if (b.id == id) return b;
    }
    return null;
  }
}

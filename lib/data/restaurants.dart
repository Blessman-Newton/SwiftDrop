import '../models/models.dart';

const List<Restaurant> restaurants = [
  Restaurant(
    id: 'rest_burger_loft',
    name: 'The Burger Loft',
    rating: 4.8,
    tags: ['Gourmet', 'American', 'Top Rated'],
    deliveryTime: '20-30 min',
    deliveryFee: 'Free',
    distance: '1.2 miles',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDAwtnPSOvN5Pceg4ID8wky_u5rFA66DS3aIdcU9HDdpgXnboIbg2WH5IG2LUUj3kr2dKFCUw7p-4rIY_ZUvY4wl4S_mvXrBYBBhKUotOa1_hW9zTdTKwGT-2SfmqWHOiYnyLfrm8AZtz2PkVfG4Go-SyfzQNHtzgeO74B--05gIqKNzubHLXPbxnLeJr4quXlNJkFH5ZL0fLvKUZW5FrhHuDu3LDVFY3Mn4zwCipAQIBwMPgtqFSQoBr8U2RbtIJMhFA7MHzmrbbw',
    isPopular: true,
    priceLevel: 2,
    menu: [
      FoodItem(
        id: 'burger_truffle',
        name: 'The Signature Truffle Burger',
        description:
            'Double wagyu beef, truffle aioli, aged cheddar, balsamic glazed onions, fresh arugula on a toasted brioche.',
        price: 14.99,
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDLVrSIUhxpiYISsP6mzg5iW6CObu2DmX6MltY7CPecY6EcpYqESAW-DSullDkIQYLKbslLSWPBUkkle7icmrO45IcULYNB0PvonGsuMFBVOLko2ftfB66oUL2bS46IxPbzXLrvG2c-HUzJI9QvV8R4MioWIYYluwg9ZoQgMkPdLwqq4Tqz-qWAF3FKU4RUSHm1dRj1Uu_KVFSipFNr3E3_2BLGGIDjakLIac8qMDkpful84yOMNxz5eiIfLcgWwpb2S8k0DLYq1KA',
        category: FoodCategory.popular,
      ),
      FoodItem(
        id: 'burger_jalapeno',
        name: 'The Spicy Jalapeño Smash',
        description:
            'Two smashed beef patties, pepper jack cheese, pickled jalapeños, and our secret habanero sauce.',
        price: 12.50,
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCP5OfEPZIea16BNegbLKPb5FPpRdFcG5wEVsIjX5uqmzNkKe-4WybLX5g1lQKXRtraEAG7yP2Sh44Xi_yiyigtSxsWdNNkX9K1_2GCSf5wtk5wnSdc1wErDpyUuGmnAeKQ7s9DyAhvJkzu8y1ukCL2ri0ozYaANQdlopij3U83XI8WucWF3XsDSE7zV_XISCXQAU4_sAp9kr0VnQLQqLr-Pk0xgu5bOyFA1_nLQPqE5bM1GtwPkOflwGefqjjynqPQDDo0xDif0fo',
        category: FoodCategory.popular,
      ),
      FoodItem(
        id: 'burger_bourbon',
        name: 'BBQ Bourbon Street',
        description:
            'Crispy bacon, onion rings, cheddar cheese, and signature bourbon BBQ sauce on a pretzel bun.',
        price: 13.99,
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAYokVGtYn_E2ZDlAANrgIKhVz7_0jQQPXJV1vvgN0-VZH7ADOV4gbRw9wAupuQfpx91KEp_91qyvFNM518ozYhBygT-ELOSMAzZ4YCiwCnOHgxjXsQ2l0TPF2FlJbVRdZedLCYtfUuYIZRAPikakWvASlwqEQU0SiKgFIAFUM5CjfpppwZsWN_5fEKyF4AM8sfbhzYSMpKrthW16l-WMF6Upk5cCU500D5TndmDn-NRWQZ-hOAO_pyl-HGDQJBCLJfoTmn0fnM9Ps',
        category: FoodCategory.burgers,
      ),
      FoodItem(
        id: 'burger_garden',
        name: 'The Garden Zenith',
        description:
            'Award-winning black bean & quinoa patty, smashed avocado, sprouts, and vegan lime aioli.',
        price: 11.99,
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuA2P37oat4Aa2994Vb2mVsobTdAKePtu_j4O9EymNUlIPSiye2kNtnJCzFDHfSyec9vhaoGJ1Nq_JKGh_IZiGwb5x5xtJjw1Ytsfmp086fNB1SNvbK14P1W6-C-V96n75tT_NSAf-luSywMc-mO7L5OP-Qg748sbyK61pW0XmrE2aCtoVYFkdICgwA2Yd17BJmEdWhbLM3MnJp71UO0YbvwoeMkUgLvbobz1VHbft7NuyQoW5UdshYDFAZKKH26MN7OMuT5iye0Z_0',
        category: FoodCategory.burgers,
      ),
      FoodItem(
        id: 'drink_ale',
        name: 'Craft Amber Ale',
        description:
            'Cold, condensation-covered glass of craft amber ale on a dark coaster.',
        price: 6.00,
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBQmZptZT_Vx6mntbwc5jPFJy-Ku11UeI2done700soJCK5SxoRXergDGaU0dbpdtewPz3fN66OJI10j7EovMGbcC7b24aM5QvvAffiXeil9XkoefRbaiGRhMRJVNeTFF864NahrEFli-fB1cGjB_FIxCP-skQSYezFWodFsZYydmgDGOIeR5pcoHT6nomMR8KBOsGRGd6EyqFY66oel24QvRdDIuNsq_eaA30lI0ED7ZfxbWgUNIvSCY8wBktOnPZRFdkqG9bJmqE',
        category: FoodCategory.drinks,
      ),
      FoodItem(
        id: 'drink_lemonade',
        name: 'Fresh Lemonade',
        description:
            'Tall glass of fresh-squeezed lemonade with ice cubes and a mint garnish.',
        price: 4.50,
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuB9mpfrs51DvDQuZur8bw1Xj1KLQ5C166tzm4KDY8Pc0wtKbFt5KmAMd-9F0xkYPY2UluZ1DdXpRHILt7nUMRJhrniSpLuXUfaRo3NAq4LUT-oGTwf2uMCe55aXl0YfnUCid9VxYDJKcUyxdJozyL-WjQH59OFnQI8vSWZEs9zvnfpDDRRzwRlWzChh66sJoDC7MKm9tHrYPTQI6r6u33wmlnYtGE7a44iI-z1hbFMUIgdTZI-aGpQuzdImSOheCmcVyHgpnQqAsVA',
        category: FoodCategory.drinks,
      ),
      FoodItem(
        id: 'drink_shake',
        name: 'Fudge Shake',
        description:
            'Thick, chocolate fudge milkshake topped with whipped cream and a cherry.',
        price: 7.00,
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCQ4OMd1oDPaj3vKtWQyeJcpZ7urCfCPViUjsdDzfGaAQzMXvE1E8viTkSyqzef2MCFV0b446pMmbld0bqA-NuJSBOUqxoSiM9P_Dn20DaIpVTFipFAdhAmL_b_N9ulBr85Nqr73j80DFRGGr88-jgrU8P14_ldMVQ7btP5K7GYSvCIffuI6WGBEjQkoyLtSogeuK1PEXJ6umiZuoCjOSQxwEWjsD9m3m2DTACwQ7Qg-OtTY51cd57LuC6H5gc4n2Y41s0KZ4FJg6Q',
        category: FoodCategory.drinks,
      ),
      FoodItem(
        id: 'drink_tea',
        name: 'Peach Iced Tea',
        description:
            'Sparkling glass of iced peach tea with lemon slices and ice.',
        price: 4.00,
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDVfM0YV64VWIaPJDL0ACCdroyrwUpefpO3f7Fd5fr5sDyfjoFAQHrLUICO5-LhK-OzzZjlU2-Jyz-iU0MuKCF78R-IrKr5xwu9qecjF0oUjgEpIi_aI85roZ8bV9s4HnpYSAZJKgsBDvy4onaoTWwcGVff0jzUzbFtY_860_aSjsW401Nl855aKChNREWHDIxPUX5nOArE2-O7Yskw_W8rDMOHOiTGwgJ6EnZR_PK5Z3jUKpoIGZcWcAT1h0nGd2VgBHHiaJXufiY',
        category: FoodCategory.drinks,
      ),
    ],
  ),
  Restaurant(
    id: 'rest_green_bistro',
    name: 'The Green Bistro',
    rating: 4.8,
    tags: ['Healthy', 'Salads', 'Pasta'],
    deliveryTime: '15-20 min',
    deliveryFee: 'Free',
    distance: '0.8 miles',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAh1FB3Uu9hsE_-U7ZAlvCaCrP3W6hxx_1q7iHJg0JiHFZilxus4-waTGL5YQAPBIBEdHl2naqkfWXUEGQdDO69hIlKK1SHCpnswOAHrLPkd6u5rqSeprRN0yN77TaD4DIDPXCqeGD-SCzDiOkJsKhz-QnezD4T9nAJmFvCsKnFtgO0HFHoH1CyGPVqED1F4HjfQkfmOAyG-CKbNQ0BJRGope6QZdEOwhC-eFEht4ls2O52fAt5Q1XO62kykZwiXLIpCGsug3o2Fww',
    isTrending: true,
    priceLevel: 2,
    menu: [
      FoodItem(
        id: 'green_caesar',
        name: 'Artisanal Avocado Caesar',
        description:
            'Crisp romaine, creamy sliced avocado, local parmigiano, and sourdough croutons with house garlic dressing.',
        price: 11.50,
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAh1FB3Uu9hsE_-U7ZAlvCaCrP3W6hxx_1q7iHJg0JiHFZilxus4-waTGL5YQAPBIBEdHl2naqkfWXUEGQdDO69hIlKK1SHCpnswOAHrLPkd6u5rqSeprRN0yN77TaD4DIDPXCqeGD-SCzDiOkJsKhz-QnezD4T9nAJmFvCsKnFtgO0HFHoH1CyGPVqED1F4HjfQkfmOAyG-CKbNQ0BJRGope6QZdEOwhC-eFEht4ls2O52fAt5Q1XO62kykZwiXLIpCGsug3o2Fww',
        category: FoodCategory.popular,
      ),
    ],
  ),
  Restaurant(
    id: 'rest_sushi_zen',
    name: 'Sushi Zen',
    rating: 4.9,
    tags: ['Japanese', 'Sushi', 'Fine Dining'],
    deliveryTime: '30-45 min',
    deliveryFee: '\$2.99',
    distance: '2.4 miles',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAQ3on-vNK5_eoS1X8H9raefOKag7o-YTYmDVIa3vblKmf62K1syxnSSZMtrrhoIsS1jatu-IzhocYP8zFdmWUYHotJrv6A1SAmFWVR_ttwJgu-GoSsfUDPacCAHTe4VauU-5ful9PKJfHJOAtxTUh_5Wku-nf6KvZEnh9fTHIamkhpMj8jTWpc1HqduC_9SBMlaTdXctuxSGkuAiOvxoyX4J675SdEvkUZr1cxbbxLA0Lmicr-g3cz6cXX0i4vyZlHHR6yd1pl_Ck',
    isNew: true,
    priceLevel: 3,
    menu: [
      FoodItem(
        id: 'sushi_platter',
        name: 'Zen Premium Platter',
        description:
            'Assorted fresh nigiri sushi including Salmon, Maguro Tuna, Hamachi, and Chef\'s custom maki rolls.',
        price: 24.99,
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAQ3on-vNK5_eoS1X8H9raefOKag7o-YTYmDVIa3vblKmf62K1syxnSSZMtrrhoIsS1jatu-IzhocYP8zFdmWUYHotJrv6A1SAmFWVR_ttwJgu-GoSsfUDPacCAHTe4VauU-5ful9PKJfHJOAtxTUh_5Wku-nf6KvZEnh9fTHIamkhpMj8jTWpc1HqduC_9SBMlaTdXctuxSGkuAiOvxoyX4J675SdEvkUZr1cxbbxLA0Lmicr-g3cz6cXX0i4vyZlHHR6yd1pl_Ck',
        category: FoodCategory.popular,
      ),
    ],
  ),
  Restaurant(
    id: 'rest_pizza_rustica',
    name: 'Pizza Rustica',
    rating: 4.9,
    tags: ['Italian', 'Pizza', 'Artisanal'],
    deliveryTime: '15-25 min',
    deliveryFee: 'Free',
    distance: '1.5 miles',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBEdppEq_fboiuFZvyeNDeosq59Q9JkKKrCIwkUlJOQIFZqY6mWr8HBq7eEhLbrALasPgujMSAU481QNBYz4uwjfE5W8nfqn9oHnRsTxg0i16smN1p2oIPQyRJCl_ZJSXW1s0LdXNQFsv06kExFsBUP1GtVuFAaBhz3Bnwdu5Zk8g0XQH5L6CRJOnx1myAZye6HArx0fsAfL06JHmhEZiwzv3seqgSy87_xDzcmjQ15Ewkx1RYjpn8gdB-jx0avIt2t-JfkUObuZQM',
    isTrending: true,
    priceLevel: 2,
    menu: [
      FoodItem(
        id: 'pizza_margherita',
        name: 'Neapolitan Margherita DOP',
        description:
            'Wood-fired crust, San Marzano tomatoes, fresh buffalo mozzarella, aromatic fresh basil leaves, extra virgin olive oil.',
        price: 15.99,
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBEdppEq_fboiuFZvyeNDeosq59Q9JkKKrCIwkUlJOQIFZqY6mWr8HBq7eEhLbrALasPgujMSAU481QNBYz4uwjfE5W8nfqn9oHnRsTxg0i16smN1p2oIPQyRJCl_ZJSXW1s0LdXNQFsv06kExFsBUP1GtVuFAaBhz3Bnwdu5Zk8g0XQH5L6CRJOnx1myAZye6HArx0fsAfL06JHmhEZiwzv3seqgSy87_xDzcmjQ15Ewkx1RYjpn8gdB-jx0avIt2t-JfkUObuZQM',
        category: FoodCategory.popular,
      ),
    ],
  ),
  Restaurant(
    id: 'rest_urban_grill',
    name: 'Urban Grill',
    rating: 4.6,
    tags: ['Steakhouse', 'Burgers', 'Gourmet'],
    deliveryTime: '25-35 min',
    deliveryFee: '\$2.99',
    distance: '1.9 miles',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDgZaqbRwx7CUEyH9VwYfNkfC1nH-A1bJLSNPoDfuU3LfnlpX0yagvLSpt7tTdtjU2qfYP6-Oeoxq_Hl5hlDOpejKQ8Kaop6Da3A02DMFMRzmAtgKsdW-4sjj6mt_S-_2j7YT3RCo1SnG2d59Wa0HAmGAy1AQSeKIoSoSDd76LUGqVxuHqUraJS93yW60oQThSJd51X8nS1a0ANiQCTcKW7eBhq4AkCMueFq6H9KVShdf0k9V9Zhzr9rfluxnluuJYJNFVnIxMVxb8',
    priceLevel: 3,
    menu: [
      FoodItem(
        id: 'grill_sirloin',
        name: 'Truffle Grilled Wagyu Sirloin',
        description:
            'Exquisite marbled prime steak served with customized herb butter and direct hot fire charring.',
        price: 28.50,
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDgZaqbRwx7CUEyH9VwYfNkfC1nH-A1bJLSNPoDfuU3LfnlpX0yagvLSpt7tTdtjU2qfYP6-Oeoxq_Hl5hlDOpejKQ8Kaop6Da3A02DMFMRzmAtgKsdW-4sjj6mt_S-_2j7YT3RCo1SnG2d59Wa0HAmGAy1AQSeKIoSoSDd76LUGqVxuHqUraJS93yW60oQThSJd51X8nS1a0ANiQCTcKW7eBhq4AkCMueFq6H9KVShdf0k9V9Zhzr9rfluxnluuJYJNFVnIxMVxb8',
        category: FoodCategory.popular,
      ),
    ],
  ),
];

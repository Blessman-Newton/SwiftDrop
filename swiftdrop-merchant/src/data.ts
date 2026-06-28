import { MenuItem, Order } from "./types";

export const INITIAL_MENU_ITEMS: MenuItem[] = [
  {
    id: "m1",
    name: "Signature Wagyu",
    description: "Double-stack wagyu beef, truffle aioli, smoked provolone, and house pickles.",
    price: 18.50,
    category: "Burgers",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBtPZPf8uj943aflmRsqlgyQLnOCvi_AWEz6GRRLKM4utZXgAHR7peXrB1fpf-hJAEgj8Wh9xe8VDyL_fpN9YTWo4cjA6D9db82hBAbhJgOS0l5dJ4n59qvkBoqfWKkW5BdGn2hla0oxcLMzyfa7hn7vsxXA0d5UQpWg8MEaMrjleojIfUEHCa9dTR6AKWt5AnNgluIjDBLWUIup7gKHl5_rmpf5nEbIf2L4Z-kTI7oHEU6r4G6Che8Tu2XtKSl9VDLqT0bdILMzX4",
    inStock: true,
    soldCount: 248,
    soldTrend: "+12%"
  },
  {
    id: "m2",
    name: "Truffle Fries",
    description: "Hand-cut russet potatoes tossed in white truffle oil and 24-month aged parmesan.",
    price: 9.00,
    category: "Sides",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuAV0xrtFVaGwuyfVGJIwdwQTb5JBbIORuPl9uHqjAZ8qqSrzfSoxGXnDies3Zeg_tmc6YHcdl41Lut6cb47tYmtSKJ2xzqkb9uhDBKkyNyAPkvVFyF8NEUhsk9Z_1GIOjAnsbdUr8sz8efwyLcC3Jaf18eQXggDNGV-Kp_kEeGCzb6qlfuhALCRRl7rNpITH5EHr9XxLy58-_Js7S4SrAnTGTBW859W7UNJcOqnIUG-yhDOWCgDi8lYyHqAuAvFxWFT7n9P0tlVS0Q",
    inStock: true,
    soldCount: 156,
    soldTrend: "+8%"
  },
  {
    id: "m3",
    name: "Zen Bowl",
    description: "Roasted seasonal vegetables, organic quinoa, and lemon-tahini dressing.",
    price: 14.25,
    category: "Popular",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBRBAm0Z9NUsZIH57rrgyZrxQ2GrptnQwJ9RNBh_mswOww0fKXTKEbIqvgQT9YGEPSVuQkKjqmhmvmSPL1jj5OanQxnKoDdS0QGrxj3y9lkio8az1QZE9MsAGE_0LRLuB3e6X6hluqjJAj5T_jGrhT5B7r8yIS6hTatuPdgSkUflzJIxM4CoZn4qI0o7UBmfA_i3gXoeGKw2igtjLqOsRBN43r-0wMYLD8aerOBkq_3_aZhrvvpzXvJr8vZGNDLKkZxbmJDuG7EwBI",
    inStock: false,
    soldCount: 192,
    soldTrend: "+5%"
  },
  {
    id: "m4",
    name: "Craft Cold Brew",
    description: "Cold brew coffee in a crystal glass with ice cubes, slow dripped for 18 hours.",
    price: 5.50,
    category: "Beverages",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuC8uPRbZVlOTY6Ezxe2rKUKVWpEKfaazecofsQrundILPrcDeCTK_PJD4K7EDy8La_MKzaYFppG4pJrKVYLEPsZU6OpcxJhcC5JVVY7OoqjqH-bj9_cy2nrYJyx6Hgqt8rXPQQgue2cWnTtPWbE13xDv33o0JXNfajRLwGh74rc9eKNoGfk_TP2vWhEh33JDgC4n5VuQVPLPYMblER955prUVgeNuJk805e0pwd_5eub7h7xY2rYLH_FqfFOY8la-CtGRGzMyR8cdY",
    inStock: true,
    soldCount: 156,
    soldTrend: "0%"
  },
  {
    id: "m5",
    name: "Avocado Harvest Bowl",
    description: "A fresh organic avocado toast with poached egg, micro-greens, on sourdough.",
    price: 14.00,
    category: "Popular",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBpLSrmR5cilFOcHwcnTMwNPIyF_4Ksk9-k2O-Uf6W2ksQTqe2qq1BAfKpFs1HB-NQSEYiBy_e1w3obduYekACnyGx_vStkV2fExecUxjK-W6ZrAwtpu-EkPbjCkIvJOZEuUHbeSfsszuRDJWELbEO0BjODIee9_eWK0gvNdfYL6wUC38n3DcVXpmu1WZ3weCWFhuTOj81BlBl4n9Ri8nE_tSyU_k-Ot4MPeahSj7Mzk7S2NZSRbdF5fAXJ4oOnar6vIPF9apR4E-g",
    inStock: true,
    soldCount: 192,
    soldTrend: "+5%"
  },
  {
    id: "m6",
    name: "Double Cheese Smasher",
    description: "Two smashed wagyu beef patties, sharp cheddar, special drop sauce, sesame brioche.",
    price: 16.50,
    category: "Burgers",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuCd0Iagz8NQC0-Sy5X5Bc4_q24cjiISVfiY9boMGv_Uqs4sscVPfEE3kSabOVRg4H0belE3a9j86tX2BIRE2vm1wsKhRUo3D_b7o1gsTWjSgJEljgvVrxZ3cghQv8RPL87A2MzZmwyJgdPy7yZKukf1bGj2qCWD44GVzsu6fCImNZpro_K1k2vynm33AtQJNZEkFbW7RjyZrFG0dtEOQgX16fEG0REsTNRnpVn5Cpal_yFwBuJU4dzAzRUxdVu94NIVlR-Ao61jFDo",
    inStock: true,
    soldCount: 310,
    soldTrend: "+18%"
  }
];

export const INITIAL_ORDERS: Order[] = [
  {
    id: "o1",
    orderNo: "SD-9281",
    status: "preparing",
    customerName: "Sarah J.",
    items: [
      { name: "Classic Burger", quantity: 2 },
      { name: "Truffle Fries", quantity: 1 }
    ],
    total: 42.50,
    elapsedSeconds: 848, // 14:08
    createdAtStr: "12:35 PM",
    driverName: "Marcus Chen",
    driverStatus: "Arriving in 2m"
  },
  {
    id: "o2",
    orderNo: "SD-9285",
    status: "new",
    customerName: "Robert L.",
    items: [
      { name: "Vegan Power Bowl", quantity: 3 },
      { name: "Green Juice", quantity: 3 }
    ],
    total: 124.00,
    elapsedSeconds: 51, // ~0:51 elapsed
    createdAtStr: "12:51 PM"
  },
  {
    id: "o3",
    orderNo: "SD-9279",
    status: "preparing",
    customerName: "Sarah J. Miller",
    items: [
      { name: "Margherita Pizza", quantity: 1 },
      { name: "Garlic Knots", quantity: 2 }
    ],
    total: 26.50,
    elapsedSeconds: 387, // 06:27
    createdAtStr: "12:20 PM"
  },
  {
    id: "o4",
    orderNo: "SD-9288",
    status: "preparing",
    customerName: "John K.",
    items: [
      { name: "Sushi Platter Deluxe", quantity: 1 },
      { name: "Miso Soup", quantity: 4 },
      { name: "Edamame", quantity: 2 },
      { name: "Tempura Shrimps", quantity: 1 }
    ],
    total: 68.00,
    elapsedSeconds: 141, // 02:21
    createdAtStr: "12:48 PM",
    driverName: "Sarah J. Miller",
    driverStatus: "Away: 1.4 km"
  },
  {
    id: "o5",
    orderNo: "SD-9290",
    status: "new",
    customerName: "Emily R.",
    items: [
      { name: "Quinoa Salad", quantity: 2 },
      { name: "Grilled Chicken", quantity: 1 }
    ],
    total: 42.00,
    elapsedSeconds: 15,
    createdAtStr: "12:55 PM"
  },
  {
    id: "o6",
    orderNo: "SD-8819",
    status: "awaiting_pickup",
    customerName: "Mike D.",
    items: [
      { name: "Signature Wagyu", quantity: 1 }
    ],
    total: 18.90,
    elapsedSeconds: 980,
    createdAtStr: "11:58 AM",
    driverName: "Courier Mike D.",
    driverStatus: "2 mins away"
  }
];

export const MERCHANT_INFO = {
  name: "Downtown Kitchen",
  chefName: "Chef Alex",
  chefAvatar: "https://lh3.googleusercontent.com/aida-public/AB6AXuAaS8d7dJRJSyw4nxMO-eZ3MOzO9uyYYDLN7sizqM4yDfzaXMDrMHfLrXJVHwl_Ddf_Mdn857JXDc3L3eid3xEhUPIjt1HRrwvrP-c5RmPckAZhbw7tGUot3ad3H_iP7u3gncOaDUNG-fmR8md2rfzWwfvuJgwuh1u0Yy1AgsXOBxvxceMoustCNYZXlPsLcrPTKSiBszDV2D0y3mS2flMevEcob39siLBMNRt3M6bG1moGExyLu75uq9PMe407WJ-wVoh3updhQZQ",
  secondaryChefAvatar: "https://lh3.googleusercontent.com/aida-public/AB6AXuBKBAhsQLG1R46JlfzVVp2Qy_Rr9A57cPwSUw-qOaFsaZruMg_WMfhLdsdUSpTDQl-89-fiPSkoSP_do1-OkscWEIs6Wfx-oWyvCKseN2yDB3LW9zZjdgKEZ50_fuRWHOE4pVXIXL5A9GtKtFlU_I5hma_jyGfpyp-LjDvge5Dgc4ygwqGOiCgf3e2BX7M-1-rn8hrawx2SRECHPNctgyF8GP6XwGgF6ESnn5_3iF23XZyrE6aHDMfLbQnoDerO1TzbfHOB1-yFXEE",
  kitchenBanner: "https://lh3.googleusercontent.com/aida-public/AB6AXuCU9c9doBCxvvHWsJEybtz9jIiKLzIUn_N2P6cRIrqNWL7b3faOSV8B6JpzUtCdAikXO8mS2ftxLSPc9Z4qZdSRWPvsOkBc5BvD5X0j_LqRCkZd48CL-4dbpOUIMDstKF5DDpNQ7DmdW3Uh_OdloAaGtegORj2ybX0nokzzXNKuPkQN2OTTenf9CT55aXJp4JOdPk-0hG4d5onZLXntANNBHNzB3wOm_OdAk_cJpTSa9iKVSB_fUZoRNHV3qfNVgl29zQrgTlLQGfA"
};

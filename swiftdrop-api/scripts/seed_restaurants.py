"""Seed database with restaurants, menu items, and promo codes."""
import asyncio
import uuid
from datetime import datetime, timezone

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import get_settings
from app.core.database import Base
from app.models.restaurant import MenuItem, PromoCode, Restaurant

settings = get_settings()
engine = create_async_engine(settings.DATABASE_URL)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

RESTAURANTS = [
    {
        "name": "The Burger Loft",
        "slug": "the-burger-loft",
        "description": "Gourmet burgers crafted with premium wagyu beef and artisanal ingredients.",
        "address": "455 West Grand Ave, Accra",
        "rating": 4.8,
        "delivery_time": "20-30 min",
        "delivery_fee": 0,
        "minimum_order": 10.00,
        "tags": ["Gourmet", "American", "Top Rated"],
        "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuDAwtnPSOvN5Pceg4ID8wky_u5rFA66DS3aIdcU9HDdpgXnboIbg2WH5IG2LUUj3kr2dKFCUw7p-4rIY_ZUvY4wl4S_mvXrBYBBhKUotOa1_hW9zTdTKwGT-2SfmqWHOiYnyLfrm8AZtz2PkVfG4Go-SyfzQNHtzgeO74B--05gIqKNzubHLXPbxnLeJr4quXlNJkFH5ZL0fLvKUZW5FrhHuDu3LDVFY3Mn4zwCipAQIBwMPgtqFSQoBr8U2RbtIJMhFA7MHzmrbbw",
        "menu": [
            {"name": "The Signature Truffle Burger", "description": "Double wagyu beef, truffle aioli, aged cheddar, balsamic glazed onions, fresh arugula on a toasted brioche.", "price": 14.99, "category": "popular", "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuDLVrSIUhxpiYISsP6mzg5iW6CObu2DmX6MltY7CPecY6EcpYqESAW-DSullDkIQYLKbslLSWPBUkkle7icmrO45IcULYNB0PvonGsuMFBVOLko2ftfB66oUL2bS46IxPbzXLrvG2c-HUzJI9QvV8R4MioWIYYluwg9ZoQgMkPdLwqq4Tqz-qWAF3FKU4RUSHm1dRj1Uu_KVFSipFNr3E3_2BLGGIDjakLIac8qMDkpful84yOMNxz5eiIfLcgWwpb2S8k0DLYq1KA"},
            {"name": "The Spicy Jalapeño Smash", "description": "Two smashed beef patties, pepper jack cheese, pickled jalapeños, and our secret habanero sauce.", "price": 12.50, "category": "popular", "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuCP5OfEPZIea16BNegbLKPb5FPpRdFcG5wEVsIjX5uqmzNkKe-4WybLX5g1lQKXRtraEAG7yP2Sh44Xi_yiyigtSxsWdNNkX9K1_2GCSf5wtk5wnSdc1wErDpyUuGmnAeKQ7s9DyAhvJkzu8y1ukCL2ri0ozYaANQdlopij3U83XI8WucWF3XsDSE7zV_XISCXQAU4_sAp9kr0VnQLQqLr-Pk0xgu5bOyFA1_nLQPqE5bM1GtwPkOflwGefqjjynqPQDDo0xDif0fo"},
            {"name": "BBQ Bourbon Street", "description": "Crispy bacon, onion rings, cheddar cheese, and signature bourbon BBQ sauce on a pretzel bun.", "price": 13.99, "category": "burgers", "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuAYokVGtYn_E2ZDlAANrgIKhVz7_0jQQPXJV1vvgN0-VZH7ADOV4gbRw9wAupuQfpx91KEp_91qyvFNM518ozYhBygT-ELOSMAzZ4YCiwCnOHgxjXsQ2l0TPF2FlJbVRdZedLCYtfUuYIZRAPikakWvASlwqEQU0SiKgFIAFUM5CjfpppwZsWN_5fEKyF4AM8sfbhzYSMpKrthW16l-WMF6Upk5cCU500D5TndmDn-NRWQZ-hOAO_pyl-HGDQJBCLJfoTmn0fnM9Ps"},
            {"name": "The Garden Zenith", "description": "Award-winning black bean & quinoa patty, smashed avocado, sprouts, and vegan lime aioli.", "price": 11.99, "category": "burgers", "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuA2P37oat4Aa2994Vb2mVsobTdAKePtu_j4O9EymNUlIPSiye2kNtnJCzFDHfSyec9vhaoGJ1Nq_JKGh_IZiGwb5x5xtJjw1Ytsfmp086fNB1SNvbK14P1W6-C-V96n75tT_NSAf-luSywMc-mO7L5OP-Qg748sbyK61pW0XmrE2aCtoVYFkdICgwA2Yd17BJmEdWhbLM3MnJp71UO0YbvwoeMkUgLvbobz1VHbft7NuyQoW5UdshYDFAZKKH26MN7OMuT5iye0Z_0"},
            {"name": "Craft Amber Ale", "description": "Cold, condensation-covered glass of craft amber ale on a dark coaster.", "price": 6.00, "category": "drinks", "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuBQmZptZT_Vx6mntbwc5jPFJy-Ku11UeI2done700soJCK5SxoRXergDGaU0dbpdtewPz3fN66OJI10j7EovMGbcC7b24aM5QvvAffiXeil9XkoefRbaiGRhMRJVNeTFF864NahrEFli-fB1cGjB_FIxCP-skQSYezFWodFsZYydmgDGOIeR5pcoHT6nomMR8KBOsGRGd6EyqFY66oel24QvRdDIuNsq_eaA30lI0ED7ZfxbWgUNIvSCY8wBktOnPZRFdkqG9bJmqE"},
            {"name": "Fresh Lemonade", "description": "Tall glass of fresh-squeezed lemonade with ice cubes and a mint garnish.", "price": 4.50, "category": "drinks", "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuB9mpfrs51DvDQuZur8bw1Xj1KLQ5C166tzm4KDY8Pc0wtKbFt5KmAMd-9F0xkYPY2UluZ1DdXpRHILt7nUMRJhrniSpLuXUfaRo3NAq4LUT-oGTwf2uMCe55aXl0YfnUCid9VxYDJKcUyxdJozyL-WjQH59OFnQI8vSWZEs9zvnfpDDRRzwRlWzChh66sJoDC7MKm9tHrYPTQI6r6u33wmlnYtGE7a44iI-z1hbFMUIgdTZI-aGpQuzdImSOheCmcVyHgpnQqAsVA"},
            {"name": "Fudge Shake", "description": "Thick, chocolate fudge milkshake topped with whipped cream and a cherry.", "price": 7.00, "category": "drinks", "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuCQ4OMd1oDPaj3vKtWQyeJcpZ7urCfCPViUjsdDzfGaAQzMXvE1E8viTkSyqzef2MCFV0b446pMmbld0bqA-NuJSBOUqxoSiM9P_Dn20DaIpVTFipFAdhAmL_b_N9ulBr85Nqr73j80DFRGGr88-jgrU8P14_ldMVQ7btP5K7GYSvCIffuI6WGBEjQkoyLtSogeuK1PEXJ6umiZuoCjOSQxwEWjsD9m3m2DTACwQ7Qg-OtTY51cd57LuC6H5gc4n2Y41s0KZ4FJg6Q"},
            {"name": "Peach Iced Tea", "description": "Sparkling glass of iced peach tea with lemon slices and ice.", "price": 4.00, "category": "drinks", "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuDVfM0YV64VWIaPJDL0ACCdroyrwUpefpO3f7Fd5fr5sDyfjoFAQHrLUICO5-LhK-OzzZjlU2-Jyz-iU0MuKCF78R-IrKr5xwu9qecjF0oUjgEpIi_aI85roZ8bV9s4HnpYSAZJKgsBDvy4onaoTWwcGVff0jzUzbFtY_860_aSjsW401Nl855aKChNREWHDIxPUX5nOArE2-O7Yskw_W8rDMOHOiTGwgJ6EnZR_PK5Z3jUKpoIGZcWcAT1h0nGd2VgBHHiaJXufiY"},
        ],
    },
    {
        "name": "The Green Bistro",
        "slug": "the-green-bistro",
        "description": "Fresh, healthy meals made with locally sourced organic ingredients.",
        "address": "12 Oxford Rd, Accra",
        "rating": 4.8,
        "delivery_time": "15-20 min",
        "delivery_fee": 0,
        "minimum_order": 8.00,
        "tags": ["Healthy", "Salads", "Pasta"],
        "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuAh1FB3Uu9hsE_-U7ZAlvCaCrP3W6hxx_1q7iHJg0JiHFZilxus4-waTGL5YQAPBIBEdHl2naqkfWXUEGQdDO69hIlKK1SHCpnswOAHrLPkd6u5rqSeprRN0yN77TaD4DIDPXCqeGD-SCzDiOkJsKhz-QnezD4T9nAJmFvCsKnFtgO0HFHoH1CyGPVqED1F4HjfQkfmOAyG-CKbNQ0BJRGope6QZdEOwhC-eFEht4ls2O52fAt5Q1XO62kykZwiXLIpCGsug3o2Fww",
        "menu": [
            {"name": "Artisanal Avocado Caesar", "description": "Crisp romaine, creamy sliced avocado, local parmigiano, and sourdough croutons with house garlic dressing.", "price": 11.50, "category": "popular", "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuAh1FB3Uu9hsE_-U7ZAlvCaCrP3W6hxx_1q7iHJg0JiHFZilxus4-waTGL5YQAPBIBEdHl2naqkfWXUEGQdDO69hIlKK1SHCpnswOAHrLPkd6u5rqSeprRN0yN77TaD4DIDPXCqeGD-SCzDiOkJsKhz-QnezD4T9nAJmFvCsKnFtgO0HFHoH1CyGPVqED1F4HjfQkfmOAyG-CKbNQ0BJRGope6QZdEOwhC-eFEht4ls2O52fAt5Q1XO62kykZwiXLIpCGsug3o2Fww"},
        ],
    },
    {
        "name": "Sushi Zen",
        "slug": "sushi-zen",
        "description": "Authentic Japanese cuisine with the freshest fish and traditional techniques.",
        "address": "34 Cantonments Rd, Accra",
        "rating": 4.9,
        "delivery_time": "30-45 min",
        "delivery_fee": 2.99,
        "minimum_order": 15.00,
        "tags": ["Japanese", "Sushi", "Fine Dining"],
        "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuAQ3on-vNK5_eoS1X8H9raefOKag7o-YTYmDVIa3vblKmf62K1syxnSSZMtrrhoIsS1jatu-IzhocYP8zFdmWUYHotJrv6A1SAmFWVR_ttwJgu-GoSsfUDPacCAHTe4VauU-5ful9PKJfHJOAtxTUh_5Wku-nf6KvZEnh9fTHIamkhpMj8jTWpc1HqduC_9SBMlaTdXctuxSGkuAiOvxoyX4J675SdEvkUZr1cxbbxLA0Lmicr-g3cz6cXX0i4vyZlHHR6yd1pl_Ck",
        "menu": [
            {"name": "Zen Premium Platter", "description": "Assorted fresh nigiri sushi including Salmon, Maguro Tuna, Hamachi, and Chef's custom maki rolls.", "price": 24.99, "category": "popular", "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuAQ3on-vNK5_eoS1X8H9raefOKag7o-YTYmDVIa3vblKmf62K1syxnSSZMtrrhoIsS1jatu-IzhocYP8zFdmWUYHotJrv6A1SAmFWVR_ttwJgu-GoSsfUDPacCAHTe4VauU-5ful9PKJfHJOAtxTUh_5Wku-nf6KvZEnh9fTHIamkhpMj8jTWpc1HqduC_9SBMlaTdXctuxSGkuAiOvxoyX4J675SdEvkUZr1cxbbxLA0Lmicr-g3cz6cXX0i4vyZlHHR6yd1pl_Ck"},
        ],
    },
    {
        "name": "Pizza Rustica",
        "slug": "pizza-rustica",
        "description": "Artisanal wood-fired pizzas with imported Italian ingredients.",
        "address": "78 Labone Ave, Accra",
        "rating": 4.9,
        "delivery_time": "15-25 min",
        "delivery_fee": 0,
        "minimum_order": 10.00,
        "tags": ["Italian", "Pizza", "Artisanal"],
        "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuBEdppEq_fboiuFZvyeNDeosq59Q9JkKKrCIwkUlJOQIFZqY6mWr8HBq7eEhLbrALasPgujMSAU481QNBYz4uwjfE5W8nfqn9oHnRsTxg0i16smN1p2oIPQyRJCl_ZJSXW1s0LdXNQFsv06kExFsBUP1GtVuFAaBhz3Bnwdu5Zk8g0XQH5L6CRJOnx1myAZye6HArx0fsAfL06JHmhEZiwzv3seqgSy87_xDzcmjQ15Ewkx1RYjpn8gdB-jx0avIt2t-JfkUObuZQM",
        "menu": [
            {"name": "Neapolitan Margherita DOP", "description": "Wood-fired crust, San Marzano tomatoes, fresh buffalo mozzarella, aromatic fresh basil leaves, extra virgin olive oil.", "price": 15.99, "category": "popular", "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuBEdppEq_fboiuFZvyeNDeosq59Q9JkKKrCIwkUlJOQIFZqY6mWr8HBq7eEhLbrALasPgujMSAU481QNBYz4uwjfE5W8nfqn9oHnRsTxg0i16smN1p2oIPQyRJCl_ZJSXW1s0LdXNQFsv06kExFsBUP1GtVuFAaBhz3Bnwdu5Zk8g0XQH5L6CRJOnx1myAZye6HArx0fsAfL06JHmhEZiwzv3seqgSy87_xDzcmjQ15Ewkx1RYjpn8gdB-jx0avIt2t-JfkUObuZQM"},
        ],
    },
    {
        "name": "Urban Grill",
        "slug": "urban-grill",
        "description": "Premium steaks and gourmet grills cooked over open flame.",
        "address": "56 Airport Rd, Accra",
        "rating": 4.6,
        "delivery_time": "25-35 min",
        "delivery_fee": 2.99,
        "minimum_order": 15.00,
        "tags": ["Steakhouse", "Burgers", "Gourmet"],
        "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuDgZaqbRwx7CUEyH9VwYfNkfC1nH-A1bJLSNPoDfuU3LfnlpX0yagvLSpt7tTdtjU2qfYP6-Oeoxq_Hl5hlDOpejKQ8Kaop6Da3A02DMFMRzmAtgKsdW-4sjj6mt_S-_2j7YT3RCo1SnG2d59Wa0HAmGAy1AQSeKIoSoSDd76LUGqVxuHqUraJS93yW60oQThSJd51X8nS1a0ANiQCTcKW7eBhq4AkCMueFq6H9KVShdf0k9V9Zhzr9rfluxnluuJYJNFVnIxMVxb8",
        "menu": [
            {"name": "Truffle Grilled Wagyu Sirloin", "description": "Exquisite marbled prime steak served with customized herb butter and direct hot fire charring.", "price": 28.50, "category": "popular", "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuDgZaqbRwx7CUEyH9VwYfNkfC1nH-A1bJLSNPoDfuU3LfnlpX0yagvLSpt7tTdtjU2qfYP6-Oeoxq_Hl5hlDOpejKQ8Kaop6Da3A02DMFMRzmAtgKsdW-4sjj6mt_S-_2j7YT3RCo1SnG2d59Wa0HAmGAy1AQSeKIoSoSDd76LUGqVxuHqUraJS93yW60oQThSJd51X8nS1a0ANiQCTcKW7eBhq4AkCMueFq6H9KVShdf0k9V9Zhzr9rfluxnluuJYJNFVnIxMVxb8"},
        ],
    },
]

PROMO_CODES = [
    {"code": "SWIFT15", "description": "15% off your order", "discount_type": "percentage", "discount_value": 15.0, "minimum_order": 10.0},
    {"code": "WELCOME10", "description": "10% off first order", "discount_type": "percentage", "discount_value": 10.0, "minimum_order": 5.0},
    {"code": "FREE5", "description": "$5 off your order", "discount_type": "flat", "discount_value": 5.0, "minimum_order": 15.0},
    {"code": "SWIFT20", "description": "20% off first order", "discount_type": "percentage", "discount_value": 20.0, "minimum_order": 20.0},
]


async def seed():
    async with async_session() as session:
        # Check if restaurants already exist
        result = await session.execute(text("SELECT COUNT(*) FROM restaurants"))
        count = result.scalar()
        if count > 0:
            print(f"Database already has {count} restaurants. Skipping seed.")
            return

        print("Seeding restaurants...")
        restaurant_ids = {}
        for r_data in RESTAURANTS:
            r_id = uuid.uuid4()
            restaurant_ids[r_data["slug"]] = r_id
            restaurant = Restaurant(
                id=r_id,
                name=r_data["name"],
                slug=r_data["slug"],
                description=r_data["description"],
                address=r_data["address"],
                rating=r_data["rating"],
                delivery_time=r_data["delivery_time"],
                delivery_fee=r_data["delivery_fee"],
                minimum_order=r_data["minimum_order"],
                tags=r_data["tags"],
                image_url=r_data["image_url"],
                is_active=True,
            )
            session.add(restaurant)

            for item in r_data["menu"]:
                menu_item = MenuItem(
                    id=uuid.uuid4(),
                    restaurant_id=r_id,
                    name=item["name"],
                    description=item["description"],
                    price=item["price"],
                    category=item["category"],
                    image_url=item["image_url"],
                    is_available=True,
                    rating=r_data["rating"],
                )
                session.add(menu_item)

        print(f"Seeded {len(RESTAURANTS)} restaurants with menu items.")

        print("Seeding promo codes...")
        for p_data in PROMO_CODES:
            promo = PromoCode(
                id=uuid.uuid4(),
                code=p_data["code"],
                description=p_data["description"],
                discount_type=p_data["discount_type"],
                discount_value=p_data["discount_value"],
                minimum_order=p_data["minimum_order"],
                is_active=True,
            )
            session.add(promo)

        await session.commit()
        print(f"Seeded {len(PROMO_CODES)} promo codes.")
        print("Done!")


if __name__ == "__main__":
    asyncio.run(seed())

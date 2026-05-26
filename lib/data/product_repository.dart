import 'package:pyin_mal_app/models/product.dart';

class ProductRepository {
  static final List<Product> allProducts = [
    Product(
      id: 'hoodie_deathwish',
      name: 'NRF Deathwish Hoodie',
      price: '45,000 MMK',
      image: 'assets/images/Male/Nrf/Hoodie/NRF Deathwish hoodie0.jpg',
      category: 'Hoodie',
      gender: 'Male',
      brand: 'NRF',
    ),
    Product(
      id: 'hoodie_ajohn',
      name: 'AJOHN V2 Hoodie',
      price: '38,000 MMK',
      image: 'assets/images/Male/Nrf/Hoodie/AJOHN V2 HOODIE.jpg',
      category: 'Hoodie',
      gender: 'Male',
      brand: 'AJOHN',
    ),
    Product(
      id: 'hoodie_abcd',
      name: 'ABCD 2XL Zip Up Hoodie',
      price: '35,000 MMK',
      image: 'assets/images/Male/Nrf/Hoodie/ABCD 2XL ZIP UP HOODIE0.jpg',
      category: 'Hoodie',
      gender: 'Male',
      brand: 'ABCD',
    ),
    Product(
      id: 'hoodie_v1',
      name: 'V1 Introduction Hoodie',
      price: '32,000 MMK',
      image: 'assets/images/Male/Nrf/Hoodie/V1 INTRODUCTION Hoodie .jpg',
      category: 'Hoodie',
      gender: 'Male',
      brand: 'NRF',
    ),
    Product(
      id: 'tee_abcd',
      name: 'ABCD Tee',
      price: '15,000 MMK',
      image: 'assets/images/Male/Nrf/Tee/ABCD TEE.jpg',
      category: 'T-Shirt',
      gender: 'Male',
      brand: 'ABCD',
    ),
    Product(
      id: 'tee_acid',
      name: 'ACID T-Shirt',
      price: '18,000 MMK',
      image: 'assets/images/Male/Nrf/Tee/ACID TSHIRT 0.jpg',
      category: 'T-Shirt',
      gender: 'Male',
      brand: 'NRF',
    ),
    Product(
      id: 'tee_nrfc',
      name: 'NRFC Jersey',
      price: '22,000 MMK',
      image: 'assets/images/Male/Nrf/Tee/NRFC Jersey0.jpg',
      category: 'T-Shirt',
      gender: 'Male',
      brand: 'NRF',
    ),
    Product(
      id: 'tee_lapses',
      name: 'LAPSES Tee Oatmeal',
      price: '19,000 MMK',
      image: 'assets/images/Male/Nrf/Tee/LAPSES TSHIRT OATMEAL0.jpg',
      category: 'T-Shirt',
      gender: 'Male',
      brand: 'LAPSES',
    ),
    Product(
      id: 'set_luna_1',
      name: 'Luna Set 1',
      price: '55,000 MMK',
      image: 'assets/images/Female/dress.set/Luna/luna set1.jpg',
      category: 'Set',
      gender: 'Female',
      brand: 'Luna',
    ),
    Product(
      id: 'set_luna_2',
      name: 'Luna Set 2',
      price: '55,000 MMK',
      image: 'assets/images/Female/dress.set/Luna/luna set2.jpg',
      category: 'Set',
      gender: 'Female',
      brand: 'Luna',
    ),
    Product(
      id: 'set_luna_3',
      name: 'Luna Set 3',
      price: '55,000 MMK',
      image: 'assets/images/Female/dress.set/Luna/luna set3.jpg',
      category: 'Set',
      gender: 'Female',
      brand: 'Luna',
    ),
    Product(
      id: 'set_luna_4',
      name: 'Luna Set 4',
      price: '55,000 MMK',
      image: 'assets/images/Female/dress.set/Luna/luna set4.jpg',
      category: 'Set',
      gender: 'Female',
      brand: 'Luna',
    ),
  ];

  static Product? getProductById(String id) {
    try {
      return allProducts.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}

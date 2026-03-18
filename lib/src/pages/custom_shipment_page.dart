import 'package:flutter/material.dart';

class CustomShipmentPage extends StatefulWidget {
  const CustomShipmentPage({Key? key}) : super(key: key);

  @override
  State<CustomShipmentPage> createState() => _CustomShipmentPageState();
}

class ParcelModel {
  TextEditingController lengthController = TextEditingController();
  TextEditingController widthController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  bool isConfirmed = false;
  
  double get volume {
    double l = double.tryParse(lengthController.text) ?? 0;
    double w = double.tryParse(widthController.text) ?? 0;
    double h = double.tryParse(heightController.text) ?? 0;
    return l * w * h;
  }
}

class _CustomShipmentPageState extends State<CustomShipmentPage> {
  List<ParcelModel> parcels = [ParcelModel()];
  final double pricePerCubicUnit = 0.05; // سعر افتراضي لحساب التكلفة بناء على الحجم
  final double taxRate = 0.10; // 10% ضريبة

  double get subTotal {
    double total = 0;
    for (var parcel in parcels) {
      if (parcel.isConfirmed) {
        // حساب السعر بناءً على الحجم، أو سعر ثابت إذا كان الحجم 0
        double parcelPrice = parcel.volume > 0 ? parcel.volume * pricePerCubicUnit : 120.0;
        total += parcelPrice;
      }
    }
    return total;
  }

  double get taxAmount => subTotal * taxRate;
  double get grandTotal => subTotal + taxAmount;

  void addParcel() {
    setState(() {
      parcels.add(ParcelModel());
    });
  }

  void confirmParcel(int index) {
    setState(() {
      parcels[index].isConfirmed = true;
      // إخفاء لوحة المفاتيح
      FocusScope.of(context).unfocus();
    });
  }

  void removeParcel(int index) {
    setState(() {
      parcels.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (var parcel in parcels) {
      parcel.lengthController.dispose();
      parcel.widthController.dispose();
      parcel.heightController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'باقة مخصصة',
            style: TextStyle(color: Color(0xFF1E3A5F), fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تفاصيل الطرد',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 12),
              
              // قائمة الطرود
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      spreadRadius: 2,
                      blurRadius: 10,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: parcels.length,
                      separatorBuilder: (context, index) => const Divider(height: 32),
                      itemBuilder: (context, index) {
                        return _buildParcelItem(index);
                      },
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: addParcel,
                      icon: const Icon(Icons.add_circle, color: Colors.red),
                      label: const Text(
                        'إضافة طرد آخر',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Text(
                'حساب التكلفة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 12),
              
              // تفاصيل التكلفة
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      spreadRadius: 2,
                      blurRadius: 10,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildCostRow('باقة الجمالة', '\$${subTotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    _buildCostRow('الضريبة', '\$${taxAmount.toStringAsFixed(2)}'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الإجمالي:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          '\$${grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100), // مساحة للزر السفلي
            ],
          ),
        ),
        
        // زر الإضافة للسلة ثابت بالأسفل
        bottomSheet: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                // منطق الإضافة للسلة هنا
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'اضافة الي السلة: \$${grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        
        // لمحاكاة شريط التنقل السفلي الموجود في الصورة
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          currentIndex: 2,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: 'الشحنات'),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.add, color: Colors.white),
              ),
              label: 'أضف شحنة',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'السلة'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'الملف'),
          ],
        ),
      ),
    );
  }

  Widget _buildParcelItem(int index) {
    final parcel = parcels[index];
    return Column(
      children: [
        if (parcels.length > 1) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'طرد ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => removeParcel(index),
              )
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(child: _buildInputField('الطول', parcel.lengthController, parcel.isConfirmed)),
            const SizedBox(width: 12),
            Expanded(child: _buildInputField('العرض', parcel.widthController, parcel.isConfirmed)),
            const SizedBox(width: 12),
            Expanded(child: _buildInputField('الارتفاع', parcel.heightController, parcel.isConfirmed)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            onPressed: parcel.isConfirmed ? null : () => confirmParcel(index),
            style: ElevatedButton.styleFrom(
              backgroundColor: parcel.isConfirmed ? Colors.green : Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              parcel.isConfirmed ? 'تم تأكيد الطرد' : 'تأكيد الطرد',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, bool isConfirmed) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          enabled: !isConfirmed,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: isConfirmed ? Colors.grey.shade100 : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(String title, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Color(0xFF1E3A5F), fontWeight: FontWeight.w500),
        ),
        Text(
          amount,
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

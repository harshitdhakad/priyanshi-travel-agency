import 'package:flutter/material.dart';
import '../../services/app_theme.dart';
import '../../services/localization_service.dart';
import '../../widgets/credits_footer.dart';

class DriverAboutScreen extends StatelessWidget {
  const DriverAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations();
    return Column(
      children: [
        Expanded(
          child: Container(
            color: AppTheme.background,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Agency header card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_car_filled,
                            size: 52,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          loc.t('app_name'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          loc.t('premium_travel'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            loc.t('splash_subtitle'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // About Us section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      loc.t('about_us'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        loc.locale == 'hi'
                            ? 'प्रियांशी ट्रैवल एजेंसी राजस्थान, भारत में स्थित एक प्रीमियम ट्रैवल सर्विस प्रदाता है। '
                                  'हम प्रोफेशनल ड्राइवर्स और अच्छी तरह से रखरखाव किए गए वाहनों के साथ अंतर-शहर और शहर के भीतर कैब सेवाएं प्रदान करते हैं। '
                                  'हमारा बेड़ा जयपुर, उदयपुर, जोधपुर, पुष्कर और अन्य प्रमुख पर्यटन स्थलों सहित राजस्थान के सभी प्रमुख पर्यटन स्थलों को कवर करता है।\n\n'
                                  'हम समय की पाबंदी, सुरक्षा और ग्राहक संतुष्टि पर गर्व करते हैं। हमारे ड्राइवर प्रशिक्षित पेशेवर हैं '
                                  'जो हर यात्री के लिए आरामदायक और सुरक्षित यात्रा सुनिश्चित करते हैं।'
                            : 'Priyanshi Travel Agency is a premium travel service provider based in Rajasthan, India. '
                                  'We offer inter-city and intra-city cab services with professional drivers and well-maintained vehicles. '
                                  'Our fleet covers major tourist destinations across Rajasthan including Jaipur, Udaipur, Jodhpur, Pushkar, and more.\n\n'
                                  'We pride ourselves on punctuality, safety, and customer satisfaction. Our drivers are trained professionals '
                                  'who ensure a comfortable and safe journey for every passenger.',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Director Card
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      loc.locale == 'hi' ? 'निर्देशक' : 'Leadership',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primary,
                                  AppTheme.primaryDark,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.business_center,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mr. Rajesh Kumar Dhakad',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  loc.locale == 'hi'
                                      ? 'संस्थापक एवं निर्देशक'
                                      : 'Founder & Director',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  loc.locale == 'hi'
                                      ? 'श्री राजेश कुमार ढाकड़, प्रियांशी ट्रैवल एजेंसी के दूरदर्शी नेता और संस्थापक हैं। '
                                            'यात्रा उद्योग में दशकों के अनुभव के साथ, उन्होंने एजेंसी को राजस्थान के सबसे विश्वसनीय ट्रैवल सर्विस प्रदाताओं में से एक के रूप में विकसित किया है। '
                                            'ग्राहक संतुष्टि और गुणवत्तापूर्ण सेवा के प्रति उनकी प्रतिबद्धता ही एजेंसी की सफलता की आधारशिला है।'
                                      : 'Mr. Rajesh Kumar Dhakad is the visionary leader and founder of Priyanshi Travel Agency. '
                                            'With decades of experience in the travel industry, he has built the agency into one of the most trusted travel service providers in Rajasthan. '
                                            'His commitment to customer satisfaction and quality service has been the cornerstone of the agency\'s success. '
                                            'Under his leadership, the fleet has grown to serve thousands of satisfied customers across the state.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.6,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Developer Card
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      loc.locale == 'hi' ? 'डेवलपर' : 'Development',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.accent, Color(0xFF6D28D9)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.code,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Harshit Dhakad',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  loc.locale == 'hi'
                                      ? 'फुल-स्टैक मोबाइल ऐप डेवलपर'
                                      : 'Full-Stack Mobile App Developer',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  loc.locale == 'hi'
                                      ? 'हर्षित ढाकड़ एक कुशल फुल-स्टैक मोबाइल एप्लिकेशन डेवलपर हैं जिन्होंने इस ऐप को बनाया है। '
                                            'Flutter, Dart और Supabase जैसे आधुनिक तकनीकों में विशेषज्ञता के साथ, उन्होंने प्रियांशी ट्रैवल एजेंसी के लिए एक सहज और शक्तिशाली प्रबंधन प्रणाली विकसित की है। '
                                            'एक सहज यूज़र इंटरफ़ेस और मज़बूत बैकएंड बनाने पर उनका ध्यान एप्लीकेशन की विश्वसनीयता और प्रदर्शन सुनिश्चित करता है।'
                                      : 'Harshit Dhakad is a skilled full-stack mobile application developer who crafted this application from the ground up. '
                                            'With expertise in modern technologies like Flutter, Dart, and Supabase, he has developed a seamless and powerful management system for Priyanshi Travel Agency. '
                                            'His focus on creating an intuitive user interface combined with a robust backend ensures the application\'s reliability and performance. '
                                            'He is passionate about building technology solutions that simplify business operations.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.6,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Our Services
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      loc.t('our_services'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _serviceItem(
                    Icons.airport_shuttle,
                    loc.locale == 'hi'
                        ? 'एयरपोर्ट ट्रांसफर'
                        : 'Airport Transfers',
                    loc.locale == 'hi'
                        ? 'सभी प्रमुख हवाई अड्डों तक पिकअप और ड्रॉप'
                        : 'Pickup and drop to all major airports',
                  ),
                  _serviceItem(
                    Icons.hotel,
                    loc.locale == 'hi' ? 'होटल ट्रांसफर' : 'Hotel Transfers',
                    loc.locale == 'hi'
                        ? 'होटलों तक आरामदायक सवारी'
                        : 'Comfortable rides to and from hotels',
                  ),
                  _serviceItem(
                    Icons.map,
                    loc.locale == 'hi' ? 'सिटी टूर' : 'City Tours',
                    loc.locale == 'hi'
                        ? 'राजस्थान के विरासत शहरों की गाइडेड टूर'
                        : 'Guided tours of Rajasthan\'s heritage cities',
                  ),
                  _serviceItem(
                    Icons.directions_car,
                    loc.locale == 'hi' ? 'आउटस्टेशन कैब' : 'Outstation Cabs',
                    loc.locale == 'hi'
                        ? 'अनुभवी ड्राइवर्स के साथ लंबी दूरी की यात्रा'
                        : 'Long-distance travel with experienced drivers',
                  ),
                  _serviceItem(
                    Icons.calendar_month,
                    loc.locale == 'hi' ? 'मासिक किराया' : 'Monthly Rentals',
                    loc.locale == 'hi'
                        ? 'मासिक आधार पर ड्राइवर के साथ वाहन'
                        : 'Vehicle with driver on monthly basis',
                  ),
                  const SizedBox(height: 28),

                  // Contact info
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      loc.t('contact'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _contactRow(
                            Icons.location_on,
                            'Plot 45, MI Road, Jaipur, Rajasthan 302001',
                          ),
                          const Divider(height: 20),
                          _contactRow(Icons.phone, '+91 141 2345678'),
                          const Divider(height: 20),
                          _contactRow(Icons.email, 'info@priyanshitravel.com'),
                          const Divider(height: 20),
                          _contactRow(
                            Icons.access_time,
                            loc.locale == 'hi'
                                ? 'सोम-शनि: सुबह 8:00 - रात 8:00'
                                : 'Mon-Sat: 8:00 AM - 8:00 PM',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.t('version'),
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        const CreditsFooter(),
      ],
    );
  }

  Widget _serviceItem(IconData icon, String title, String desc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}

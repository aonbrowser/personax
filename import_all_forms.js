// PersonaX - Tüm Form Verilerini Import Etme Scripti
// Chrome DevTools Console'da çalıştır
// NOT: "allow pasting" yazarak yapıştırmayı etkinleştir

// Mevcut verileri temizle
localStorage.removeItem('form1_answers');
localStorage.removeItem('form2_answers');
localStorage.removeItem('form3_answers');
localStorage.removeItem('form1_responses');
localStorage.removeItem('form2_responses');
localStorage.removeItem('form3_responses');

// FORM 1 - Tanışalım (Demografik ve Yaşam Görüşü)
const form1_answers = {
  "F1_AGE": "47",
  "F1_GENDER": "0",
  "F1_RELATIONSHIP": "0",
  "F1_EDUCATION": "2",
  "F1_OCCUPATION": "girişimciyim. kendi işimi yapıyorum ama evden çalışıyorum. online ticaret ama bir tech startup gerçekleştirmek için uğraşıyorum",
  "F1_LIFE_SATISFACTION": 3,
  "F1_STRESS_LEVEL": 7,
  "F1_FOCUS_AREAS": ["6", "0", "3"],
  "F1_BIGGEST_CHALLENGE": "aidiyet duygusu sorunu yaşıyorum. kendimi ait hissedeceğim bir yer arıyorum ama çok iyi gitmiyor bu süreç",
  "F1_YEARLY_GOAL": "yapay zeka konusunda insanlığın büyük atılımlar yapması. \n(geriye yaşlanmanın mümkün hala gelmesine dair önemli kilometre taşlarının aşılması)\nbir kaç tech startup ımın başarılı olmuş olması. \n",
  "F1_SLEEP_QUALITY": 7,
  "F1_PHYSICAL_ACTIVITY": "0",
  "F1_ENERGY_LEVEL": 5
};

// FORM 2 - Kişilik (Big Five, MBTI, Values)
const form2_answers = {
  "F2_BIG5_01": 4,
  "F2_BIG5_02": 1,
  "F2_BIG5_03": 4,
  "F2_BIG5_04": 4,
  "F2_BIG5_05": 4,
  "F2_BIG5_06": 4,
  "F2_BIG5_07": 4,
  "F2_BIG5_08": 4,
  "F2_BIG5_09": 4,
  "F2_BIG5_10": 2,
  "F2_MBTI_01": "1",
  "F2_MBTI_02": "1",
  "F2_MBTI_03": "1",
  "F2_MBTI_04": "0",
  "F2_MBTI_05": "0",
  "F2_MBTI_06": "1",
  "F2_MBTI_07": "0",
  "F2_MBTI_08": "0",
  "F2_MBTI_09": "0",
  "F2_MBTI_10": "1",
  "F2_MBTI_11": "0",
  "F2_MBTI_12": "0",
  "F2_MBTI_13": "0",
  "F2_MBTI_14": "1",
  "F2_MBTI_15": "0",
  "F2_MBTI_16": "1",
  "F2_MBTI_17": "0",
  "F2_MBTI_18": "1",
  "F2_MBTI_19": "0",
  "F2_MBTI_20": "1",
  "F2_VALUES": ["power", "hedonism", "achievement", "self_direction", "security", "universalism", "stimulation", "conformity", "benevolence", "tradition"]
};

// FORM 3 - Davranış (Beliefs, Attachment, Stories, DISC, Conflict, Emotion, Empathy)
const form3_answers = {
  // Belief Questions
  "F3_BELIEF_01": 3,
  "F3_BELIEF_02": 2,
  "F3_BELIEF_03": 5,
  "F3_BELIEF_04": 2,
  "F3_BELIEF_05": 4,
  "F3_BELIEF_06": 2,
  
  // Attachment Style
  "F3_ATTACH_01": 5,
  "F3_ATTACH_02": 4,
  "F3_ATTACH_03": 2,
  "F3_ATTACH_04": 5,
  "F3_ATTACH_05": 5,
  "F3_ATTACH_06": 3,
  
  // Story Questions
  "F3_STORY_01": "çocukluğumdaki yaz tatilleri. yaşımın 12-15 arası olduğu aralık özellikle. evden uzaklaşıp arkadaşlarımla dere kenarına gittiğimizde veya bir arkadaşımın ailesinin az kullanılan eski evinde akşamları buluştuğumuzda",
  "F3_STORY_02": "derin düşünme ve analitik konularda zekiyim. başkalarının cesaret edemediği riskler alıyorum ve başardığım dönemler oluyorum. her şeyi başarabilecekmişim gibi bir inancım var. tanıdıkları en bilgili insan benim. özellikle tartışmalarda zekamı kullanış şeklimden etkilenirler",
  "F3_STORY_03": "daha iyi bir fiziki görünüm (daha uzun boylu daha yakışıklı daha güçlü. bu bana beraberinde daha bi özgüven getirecektir. içimdeki alfa ruhu ortaya çıkaracaktır)\nzeka seviyemden memnunum ama Dehb veya borderline gibi sorunlarımın olma olasılığı yüksek. bu da benim verimli olmamı çok engelliyor. devamlı kafamı kullanmak bana çok yorucu geliyor. \ndoğduğum büyüdüğüm aileyi içinde yetiştiğim ülkeyi arkadaşlarımı eğitim aldığım okulları vs hepsini değiştirirdim",
  "F3_STORY_04": "5 ay askerlikten sonra terhis olacağım günün sabahı hayatımın en mutlu anısı\n12 günlük tedavilerinin ardında iki abyssian yavru kedime kavuştuğum an\naşık olduğum kadınların bana karşılık verip benden hoşlandıklarını hissettiğim ilk anlar çok mutlu olurum",
  "F3_STORY_05": "abimle köyde kavga edip onun kolyesini parçaladığım an. çocuktuk. abim için kıymetliydi. muhtemelen abim haksızdı ama onun için üzülmüştüm\nbabamdan devamlı fiziki ve piskolojik şiddet gördüğüm zamanlar. evden kurtulmak istiyordum ama beş parasız, köyde yaşayan bir çocuktum sadece. kaçıp sığınabileceğim kadar beni önemseyecek hiç kimse yoktu hayatımda. hala daha yok\nabim ben ve abimin eşi beraber yaşarken 1 tl dahi paramızın olmadığı, sabah kahvaltı edebileceğimiz hiç bir şeyin olmadığı bir anı var aklımda. o çaresizliği abim ve yengemle birlikte yaşamak çok travmatikti",
  "F3_STORY_06": "liseyi daha etkili şekilde okuyup iyi bir üniversite kazanıp çok daha erken başlamalıydım hayata\nüniversitede bölüm seçimlerini daha iyi yapıp sosyal hayat imkanları çok daha yüksek olan bir bir işe yönelik tercihler yapmalıydım.\nticaret yerine kariyer tercih etmeliydim. zekiydim ve çalışkandım. şu anda muhtemelen büyük bir şirkette CEO falandım . çok geniş bir çevrem vardı, kendim daha donanımlıydım özellikle sosyal beceriler konusunda. dünyam çok daha genişti. buraya kadar olan süreçte de çok daha iyi anılar biriktirmiştim",
  "F3_STORY_07": "24 yaşındakyekn kızın biri benden hamile olduğunu söylemişti. o kızdan kesinlike bir çocuk istemiyordum ve o çok inatçıydı çocuğu doğurmak konusunda. çok ılımlı yaklaştım mantık dahilinde her türlü doğru tavrı sergilemeye çalıştım. çok akıll danıştım sağa sola ama hiç biri  işe yaramadı. ama bi gün bunu kesin olarak halletmeye karar verdim ve sabah atlayıp ofisine gittim. gayet soğuk aşırı kararlı aşırı umursamaz bir tavrım vardı. doğur istediğğin kadar doğur, 3 tane çocuk da ankarada var 4. yü de sen doğur. zerre umrumda değil dedim. bu esnada emirler yağdırıyordum. kahvaltı hazırla çay getir şunu yap bunu yap. hatta bir defa da seviştik. ve sevişmekten ziyade sex için onu kullandığım belliydi. en son üstümü toplayıp hoşçakal bile demeden çıktım. 1 saat sonra telefon geldi. tamam çocuğu aldıracağım diye. kendimi çok başarılı hissettim. olmam gereken adam oydu bence ama olamadım sonra",
  "F3_STORY_08": "en büyük umudum AI in ASI ye dönüştüğü bir ütopya. o değilse de büyük bir tech şirkketi kurup hayatımın önceki bölümlerinde yapamadıklarımı bundan sonra yapmak. finansal olarak kendimi güvencede hissetmek. \nen büyük korkumsa bunların hiç birini yapamadan manevi gücümün tükendiği, finansal olarak çöküp kedilerime bile bakamadığım bir durum. o noktada ölmek en iyi seçenekmiş gibi görünüyor. ayrıca yaşlanmaktan da korkuyorum",
  
  // Conflict Style
  "S3_CONFLICT_1": "A",
  "S3_CONFLICT_2": "B",
  
  // Emotion Regulation
  "S3_EMOTION_REG_1": 3,
  "S3_EMOTION_REG_2": 3,
  "S3_EMOTION_REG_3": 2,
  "S3_EMOTION_REG_4": 2,
  "S3_EMOTION_REG_5": 2,
  "S3_EMOTION_REG_6": 2,
  
  // Empathy
  "S3_EMPATHY_1": 4,
  "S3_EMPATHY_2": 2,
  "S3_EMPATHY_3": 3,
  "S3_EMPATHY_4": 4,
  "S3_EMPATHY_5": 5,
  "S3_EMPATHY_6": 5,
  
  // DISC Assessment
  "F3_DISC_01": {"most": "3", "least": "0"},
  "F3_DISC_02": {"most": "0", "least": "1"},
  "F3_DISC_03": {"most": "0", "least": "2"},
  "F3_DISC_04": {"most": "0", "least": "1"},
  "F3_DISC_05": {"most": "0", "least": "2"},
  "F3_DISC_06": {"most": "1", "least": "3"},
  "F3_DISC_07": {"most": "1", "least": "3"},
  "F3_DISC_08": {"most": "3", "least": "1"},
  "F3_DISC_09": {"most": "1", "least": "3"},
  "F3_DISC_10": {"most": "0", "least": "3"}
};

// Email bilgisi
const userEmail = "test@test.com";

// ============= IMPORT İŞLEMİ =============

// 1. Email'i kaydet
localStorage.setItem('userEmail', userEmail);

// 2. Form cevaplarını kaydet (NewFormsScreen'in beklediği format)
localStorage.setItem('form1_answers', JSON.stringify(form1_answers));
localStorage.setItem('form2_answers', JSON.stringify(form2_answers));
localStorage.setItem('form3_answers', JSON.stringify(form3_answers));

// 3. Tüm formların tamamlandığını işaretle
localStorage.setItem('allFormsCompleted', 'true');

// 4. Son görülen form numarasını ayarla
localStorage.setItem('lastViewedForm', '3');

// 5. Başarı mesajı
console.log('%c✅ TÜM FORMLAR BAŞARIYLA İMPORT EDİLDİ!', 'color: green; font-size: 16px; font-weight: bold');
console.log('=====================================');
console.log('📋 Form 1 (Tanışalım):', Object.keys(form1_answers).length, 'cevap');
console.log('📋 Form 2 (Kişilik):', Object.keys(form2_answers).length, 'cevap');
console.log('📋 Form 3 (Davranış):', Object.keys(form3_answers).length, 'cevap');
console.log('📧 Email:', userEmail);
console.log('=====================================');
console.log('%c⚠️ ŞİMDİ YAPMAN GEREKENLER:', 'color: orange; font-size: 14px; font-weight: bold');
console.log('1. Sayfayı yenile (F5)');
console.log('2. "Analizlerim" sayfasına git');
console.log('3. "Cevapları Düzenle" butonuna tıkla');
console.log('4. Tüm formların dolu olduğunu göreceksin!');

// Doğrulama
const checkData = () => {
  console.log('\n📊 Veri Doğrulama:');
  console.log('Form 1:', localStorage.getItem('form1_answers') ? '✅' : '❌');
  console.log('Form 2:', localStorage.getItem('form2_answers') ? '✅' : '❌');
  console.log('Form 3:', localStorage.getItem('form3_answers') ? '✅' : '❌');
};

checkData();
from app.services.ai_language_service import resolve_language


GENERAL_TOPICS = [
    {
        "keywords": {"study", "study plan", "focus", "concentration", "पढ़ाई", "अध्ययन"},
        "en": (
            "Use a simple weekly study cycle: review each lecture within 24 hours, "
            "work in focused 25- to 45-minute blocks, practise active recall, and test "
            "yourself at the end of the week. Give extra time to lower-performing subjects."
        ),
        "hi": (
            "एक सरल साप्ताहिक अध्ययन चक्र अपनाएं: हर कक्षा को 24 घंटे के भीतर दोहराएं, "
            "25 से 45 मिनट के केंद्रित सत्र रखें, सक्रिय स्मरण का अभ्यास करें और सप्ताह के "
            "अंत में स्वयं का परीक्षण करें। कमजोर विषयों को अतिरिक्त समय दें।"
        ),
    },
    {
        "keywords": {"exam preparation", "prepare for exam", "prepare for exams", "revision", "exam tips", "परीक्षा की तैयारी", "पुनरावर्तन"},
        "en": (
            "Start with the syllabus and exam dates, divide topics into small daily goals, "
            "solve previous questions under time limits, and keep the final day for light "
            "revision and sleep. Use your live timetable and results to prioritize subjects."
        ),
        "hi": (
            "पाठ्यक्रम और परीक्षा तिथियों से शुरुआत करें, विषयों को छोटे दैनिक लक्ष्यों में "
            "बांटें, समय सीमा में पुराने प्रश्न हल करें और अंतिम दिन हल्का पुनरावर्तन व पूरी "
            "नींद रखें। विषयों की प्राथमिकता के लिए समय-सारणी और परिणाम देखें।"
        ),
    },
    {
        "keywords": {"time management", "manage time", "procrastination", "समय प्रबंधन"},
        "en": (
            "List three important outcomes for the day, block fixed class and travel time "
            "first, then schedule focused study blocks. Keep one buffer block for unfinished "
            "work and review the plan each evening."
        ),
        "hi": (
            "दिन के तीन महत्वपूर्ण लक्ष्य लिखें। पहले कक्षा और यात्रा का निश्चित समय रखें, "
            "फिर केंद्रित अध्ययन सत्र तय करें। अधूरे काम के लिए एक अतिरिक्त समय रखें और हर "
            "शाम योजना की समीक्षा करें।"
        ),
    },
    {
        "keywords": {"resume", "cv", "internship", "career", "बायोडाटा", "इंटर्नशिप", "करियर"},
        "en": (
            "Keep a one-page resume with education, relevant skills, two or three projects, "
            "experience, and measurable achievements. Tailor it to each role and verify every "
            "claim. For internships, apply early and maintain a simple application tracker."
        ),
        "hi": (
            "एक पृष्ठ का बायोडाटा रखें जिसमें शिक्षा, संबंधित कौशल, दो या तीन परियोजनाएं, "
            "अनुभव और मापने योग्य उपलब्धियां हों। हर भूमिका के अनुसार इसे बदलें और सभी दावों "
            "की पुष्टि करें। इंटर्नशिप के लिए समय से आवेदन करें।"
        ),
    },
    {
        "keywords": {"phishing", "password", "cyber safety", "online safety", "पासवर्ड", "साइबर सुरक्षा"},
        "en": (
            "Use a unique password and multi-factor authentication, never share OTPs, and "
            "check the sender and web address before opening a link. Report suspicious campus "
            "messages through Helpdesk."
        ),
        "hi": (
            "अलग और मजबूत पासवर्ड तथा बहु-स्तरीय प्रमाणीकरण का उपयोग करें। OTP कभी साझा "
            "न करें और लिंक खोलने से पहले प्रेषक व वेबसाइट पता जांचें। संदिग्ध कैंपस संदेश "
            "हेल्पडेस्क पर रिपोर्ट करें।"
        ),
    },
    {
        "keywords": {"stress", "anxiety", "mental health", "wellbeing", "तनाव", "चिंता", "मानसिक स्वास्थ्य"},
        "en": (
            "Pause, reduce the next task to one small step, keep regular sleep and meals, and "
            "speak with someone you trust. For persistent distress, contact the university's "
            "authorised counselling or student-support office. If there is immediate danger, "
            "contact local emergency services."
        ),
        "hi": (
            "थोड़ा रुकें, अगले काम को एक छोटे चरण में बांटें, नींद और भोजन नियमित रखें तथा "
            "किसी विश्वसनीय व्यक्ति से बात करें। लगातार परेशानी होने पर विश्वविद्यालय की "
            "अधिकृत परामर्श या छात्र सहायता सेवा से संपर्क करें। तत्काल खतरे में स्थानीय "
            "आपातकालीन सेवा से संपर्क करें।"
        ),
    },
    {
        "keywords": {"plagiarism", "citation", "research ethics", "साहित्यिक चोरी", "शोध नैतिकता"},
        "en": (
            "Plagiarism is presenting another person's words or ideas as your own. Quote exact "
            "words, cite every borrowed idea, keep source notes while researching, and follow "
            "the citation style required by your department."
        ),
        "hi": (
            "साहित्यिक चोरी का अर्थ किसी अन्य के शब्दों या विचारों को अपना बताना है। सटीक "
            "शब्दों को उद्धरण में रखें, लिए गए हर विचार का संदर्भ दें और विभाग द्वारा निर्धारित "
            "संदर्भ शैली का पालन करें।"
        ),
    },
    {
        "keywords": {"artificial intelligence", "what is ai", "machine learning", "कृत्रिम बुद्धिमत्ता", "मशीन लर्निंग"},
        "en": (
            "Artificial intelligence is the field of building systems that perform tasks such "
            "as reasoning, prediction, language understanding, and perception. Machine learning "
            "is a part of AI where models learn patterns from data."
        ),
        "hi": (
            "कृत्रिम बुद्धिमत्ता ऐसे तंत्र बनाने का क्षेत्र है जो तर्क, पूर्वानुमान, भाषा समझ "
            "और पहचान जैसे कार्य कर सकें। मशीन लर्निंग AI का भाग है जिसमें मॉडल डेटा से "
            "पैटर्न सीखते हैं।"
        ),
    },
    {
        "keywords": {"python", "programming language", "coding basics", "पायथन", "प्रोग्रामिंग"},
        "en": (
            "Python is a general-purpose programming language known for readable syntax. "
            "A good learning order is variables and data types, conditions, loops, functions, "
            "collections, files, error handling, and then a small project."
        ),
        "hi": (
            "Python एक सामान्य उपयोग की प्रोग्रामिंग भाषा है जिसकी लिखावट सरल होती है। "
            "सीखने का अच्छा क्रम है: variables और data types, conditions, loops, functions, "
            "collections, files, error handling और फिर एक छोटी परियोजना।"
        ),
    },
    {
        "keywords": {"database", "dbms", "sql", "डेटाबेस", "एसक्यूएल"},
        "en": (
            "A database stores organised data. A DBMS controls storage, retrieval, security, "
            "and consistency. SQL is commonly used to define tables and query relational data."
        ),
        "hi": (
            "डेटाबेस व्यवस्थित डेटा को संग्रहित करता है। DBMS संग्रह, खोज, सुरक्षा और "
            "संगति को नियंत्रित करता है। SQL का उपयोग relational data की tables बनाने और "
            "query करने के लिए किया जाता है।"
        ),
    },
    {
        "keywords": {"scholarship", "financial aid", "छात्रवृत्ति"},
        "en": (
            "Scholarship eligibility and deadlines vary by scheme. Check the current official "
            "university notice or scholarship portal, keep identity, income, category, bank, "
            "and academic documents ready, and use Helpdesk when a campus-specific rule is unclear."
        ),
        "hi": (
            "छात्रवृत्ति की पात्रता और अंतिम तिथि योजना के अनुसार बदलती है। वर्तमान आधिकारिक "
            "विश्वविद्यालय सूचना या छात्रवृत्ति पोर्टल देखें तथा पहचान, आय, श्रेणी, बैंक और "
            "शैक्षणिक दस्तावेज तैयार रखें। कैंपस नियम स्पष्ट न हो तो हेल्पडेस्क का उपयोग करें।"
        ),
    },
    {
        "keywords": {"library", "books", "journal", "पुस्तकालय", "किताब"},
        "en": (
            "Use the university library catalogue to locate books and journals, carry your "
            "student ID, observe borrowing and return rules, and verify current opening hours "
            "from an official notice because timings can change."
        ),
        "hi": (
            "किताबें और शोध पत्र खोजने के लिए विश्वविद्यालय पुस्तकालय सूची का उपयोग करें, "
            "छात्र पहचान पत्र साथ रखें और निर्गमन-वापसी नियमों का पालन करें। समय बदल सकता है, "
            "इसलिए वर्तमान खुलने का समय आधिकारिक सूचना से जांचें।"
        ),
    },
    {
        "keywords": {"ragging", "harassment", "bullying", "रैगिंग", "उत्पीड़न"},
        "en": (
            "Ragging, harassment, and bullying should be reported promptly through the "
            "university's authorised safety, anti-ragging, or student-support channel. Preserve "
            "relevant evidence. If anyone is in immediate danger, contact local emergency services."
        ),
        "hi": (
            "रैगिंग, उत्पीड़न या धमकाने की घटना विश्वविद्यालय की अधिकृत सुरक्षा, एंटी-रैगिंग "
            "या छात्र सहायता सेवा को तुरंत बताएं और संबंधित प्रमाण सुरक्षित रखें। तत्काल खतरे "
            "में स्थानीय आपातकालीन सेवा से संपर्क करें।"
        ),
    },
    {
        "keywords": {"general information", "what do you know", "general help", "सामान्य जानकारी"},
        "en": (
            "I can provide general guidance on study planning, exam preparation, time management, "
            "careers, digital safety, wellbeing, research ethics, AI, Python, databases, libraries, "
            "scholarships, and student safety. Campus-specific policies come only from approved "
            "university knowledge."
        ),
        "hi": (
            "मैं अध्ययन योजना, परीक्षा तैयारी, समय प्रबंधन, करियर, डिजिटल सुरक्षा, स्वास्थ्य, "
            "शोध नैतिकता, AI, Python, डेटाबेस, पुस्तकालय, छात्रवृत्ति और छात्र सुरक्षा पर "
            "सामान्य मार्गदर्शन दे सकता हूं। कैंपस के विशेष नियम केवल स्वीकृत विश्वविद्यालय "
            "जानकारी से बताए जाते हैं।"
        ),
    },
]


def answer_general_question(
    message: str,
    requested_language: str = "auto",
) -> tuple[str | None, str, list[str]]:
    normalized = " ".join(message.lower().split())
    language = resolve_language(requested_language, message)
    for topic in GENERAL_TOPICS:
        if any(keyword in normalized for keyword in topic["keywords"]):
            suggestions = (
                ["मेरी अध्ययन योजना बताएं", "आज की समय-सारणी दिखाएं", "मेरी सहायता चेतावनियां दिखाएं"]
                if language == "hi"
                else ["Show my study recommendations", "Show today's timetable", "Show my support alerts"]
            )
            return topic[language], language, suggestions
    return None, language, []

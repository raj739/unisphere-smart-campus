import re


SUPPORTED_LANGUAGES = {"auto", "en", "hi"}


def resolve_language(requested: str | None, message: str) -> str:
    language = (requested or "auto").lower().split("-")[0]
    if language in {"en", "hi"}:
        return language
    if any("\u0900" <= character <= "\u097f" for character in message):
        return "hi"
    roman_hindi = {
        "mera",
        "meri",
        "mere",
        "mujhe",
        "batao",
        "dikhao",
        "kya",
        "kaise",
        "kitna",
        "kitni",
        "aaj",
        "kal",
        "hai",
    }
    words = set(re.findall(r"[a-z]+", message.lower()))
    return "hi" if len(words.intersection(roman_hindi)) >= 2 else "en"


def localize_grounded_answer(answer: str, language: str) -> str:
    if language != "hi":
        return answer

    replacements = [
        (r"^Your overall attendance is", "आपकी कुल उपस्थिति"),
        (r"counted classes", "गिनी गई कक्षाएं"),
        (r"\((\d+) of (\d+) गिनी गई कक्षाएं\)", r"(\2 में से \1 गिनी गई कक्षाएं)"),
        (r"Courses below the 75% target:", "75% लक्ष्य से कम उपस्थिति वाले विषय:"),
        (
            r"Attend upcoming classes consistently and contact the faculty member if an absence has been recorded incorrectly\.",
            "आगामी कक्षाओं में नियमित रहें और अनुपस्थिति गलत दर्ज होने पर संबंधित शिक्षक से संपर्क करें।",
        ),
        (r"No active course is currently below the 75% target\.", "कोई सक्रिय विषय अभी 75% लक्ष्य से कम नहीं है।"),
        (r"Attendance data has not been recorded for your active courses yet\.", "आपके सक्रिय विषयों की उपस्थिति अभी दर्ज नहीं हुई है।"),
        (r"^Your current average grade point is", "आपका वर्तमान औसत ग्रेड पॉइंट"),
        (r"No published results are available in your account yet\.", "आपके खाते में अभी कोई प्रकाशित परिणाम उपलब्ध नहीं है।"),
        (r"grade point", "ग्रेड पॉइंट"),
        (r"grade ", "ग्रेड "),
        (r"marks ", "अंक "),
        (r"Your weekly timetable:", "आपकी साप्ताहिक समय-सारणी:"),
        (r"Your ([A-Za-z]+) timetable:", r"आपकी \1 की समय-सारणी:"),
        (r"You have no timetable entries on ([A-Za-z]+)\.", r"\1 को आपकी कोई कक्षा निर्धारित नहीं है।"),
        (r"No active timetable entries are available for your enrolled courses\.", "आपके नामांकित विषयों की सक्रिय समय-सारणी उपलब्ध नहीं है।"),
        (r"registration approved", "पंजीकरण स्वीकृत"),
        (r"registration registered", "पंजीकरण दर्ज"),
        (r"The paper schedule has not been published yet\.", "प्रश्नपत्र की समय-सारणी अभी प्रकाशित नहीं हुई है।"),
        (r"No examination registration is available in your account\.", "आपके खाते में कोई परीक्षा पंजीकरण उपलब्ध नहीं है।"),
        (r"Fee summary: invoiced", "शुल्क सारांश: कुल बिल"),
        (r", paid", ", भुगतान"),
        (r", and outstanding", ", और बकाया"),
        (r" outstanding, status ", " बकाया, स्थिति "),
        (r", due ", ", देय तिथि "),
        (r"Use the Fees section to review invoice and payment details\.", "बिल और भुगतान विवरण देखने के लिए शुल्क अनुभाग खोलें।"),
        (r"No fee invoice is available in your account\.", "आपके खाते में कोई शुल्क बिल उपलब्ध नहीं है।"),
        (r"Your hostel allocation is", "आपका छात्रावास आवंटन"),
        (r", room ", ", कमरा "),
        (r", floor ", ", मंजिल "),
        (r", type ", ", प्रकार "),
        (r", status ", ", स्थिति "),
        (r"You do not currently have an active hostel allocation\.", "अभी आपका कोई सक्रिय छात्रावास आवंटन नहीं है।"),
        (r"Recent hostel complaints:", "हाल की छात्रावास शिकायतें:"),
        (r"Your route is", "आपका मार्ग"),
        (r"Pickup stop:", "पिकअप स्टॉप:"),
        (r"Landmark:", "पहचान स्थल:"),
        (r"Vehicle:", "वाहन:"),
        (r"driver:", "चालक:"),
        (r"contact:", "संपर्क:"),
        (r"You do not currently have an active transport allocation\.", "अभी आपका कोई सक्रिय परिवहन आवंटन नहीं है।"),
        (r"Recent transport issues:", "हाल की परिवहन समस्याएं:"),
        (r"Issued certificates:", "जारी प्रमाणपत्र:"),
        (r"Certificate requests:", "प्रमाणपत्र अनुरोध:"),
        (r"Open Certificates to download issued items or submit a new request\.", "जारी प्रमाणपत्र डाउनलोड करने या नया अनुरोध भेजने के लिए प्रमाणपत्र अनुभाग खोलें।"),
        (r"Your recent helpdesk tickets:", "आपके हाल के हेल्पडेस्क टिकट:"),
        (r"You have no helpdesk tickets\.", "आपका कोई हेल्पडेस्क टिकट नहीं है।"),
        (r"Active support alerts:", "सक्रिय सहायता चेतावनियां:"),
        (r"You have no active support alerts\.", "आपकी कोई सक्रिय सहायता चेतावनी नहीं है।"),
        (r"Active support cases:", "सक्रिय सहायता मामले:"),
        (r"Your current status is", "आपकी वर्तमान स्थिति"),
        (r"Your active courses:", "आपके सक्रिय विषय:"),
        (r"^Hello ([^.]+)\.", r"नमस्ते \1।"),
        (r"I can help with your", "मैं आपकी इन सेवाओं में सहायता कर सकता हूं:"),
        (r"courses, attendance, results, timetable, examinations, fees, hostel, transport, certificates, helpdesk, and student-success support\.", "विषय, उपस्थिति, परिणाम, समय-सारणी, परीक्षा, शुल्क, छात्रावास, परिवहन, प्रमाणपत्र, हेल्पडेस्क और छात्र सहायता।"),
        (r"You are ([^,]+), student ID", r"आप \1 हैं, छात्र आईडी"),
        (r", enrolled in", ", पाठ्यक्रम"),
        (r", semester", ", सेमेस्टर"),
        (r"Enrollment number:", "नामांकन संख्या:"),
        (r"faculty not assigned", "शिक्षक नियुक्त नहीं"),
        (r"not available", "उपलब्ध नहीं"),
    ]
    localized = answer
    for pattern, replacement in replacements:
        localized = re.sub(pattern, replacement, localized, flags=re.MULTILINE)
    return localized


def language_label(language: str) -> str:
    return "Hindi" if language == "hi" else "English"

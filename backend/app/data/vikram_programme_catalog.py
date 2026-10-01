"""Normalized Vikram University programme catalogue supplied for UniSphere."""

DEPARTMENTS = {
    "ARTS": "Faculty of Arts and Social Sciences",
    "MGMT": "Faculty of Commerce and Management",
    "SCI": "Faculty of Science and Technology",
    "ENG": "School of Engineering and Technology",
    "EDU": "Faculty of Education",
    "PHARM": "Institute of Pharmacy",
    "LAW": "School of Law",
    "PROF": "Professional and Vocational Studies",
    "CONT": "Continuing Education",
    "RESEARCH": "Research Programmes",
}


def _programme(
    code,
    name,
    category,
    department,
    duration,
    specializations=(),
):
    return {
        "code": code,
        "name": name,
        "category": category,
        "department": department,
        "duration_years": duration,
        "specializations": list(specializations),
    }


def _standalone(prefix, names, category, department, duration=1):
    return [
        _programme(
            f"{prefix}-{index:03d}",
            name,
            category,
            department,
            duration,
        )
        for index, name in enumerate(names, start=1)
    ]


GENERAL = "Plain"

BA_SPECIALIZATIONS = (
    "Economics",
    "English",
    "Event Management",
    "History",
    "Jyotirvigyan",
    "Mass Communication & Journalism",
    "Multimedia & Mass Communication",
    "Political Science",
    "Public Administration",
    "Sanskrit",
    "Sociology",
    "Ved",
)

BSC_SPECIALIZATIONS = (
    "Agriculture",
    "Aviation",
    "Biotechnology",
    "Botany",
    "Chemistry",
    "Computer Science",
    "Criminology",
    "Environmental Science",
    "Forensic Science",
    "Food Technology",
    "Geology",
    "Maths",
    "Microbiology",
    "Pharmaceutical Manufacturing & Quality",
    "Physics",
    "Statistics & Data Science",
    "Zoology",
)

MA_SPECIALIZATIONS = (
    "Agriculture Communication",
    "A.I.H.C. & Archaeology",
    "Economics",
    "Education",
    "English",
    "Film Studies",
    "Hindi",
    "Human Rights",
    "Indian Knowledge System",
    "Journalism",
    "Jyotirvigyan",
    "Mass Communication",
    "Media Management",
    "Modern History",
    "Photography",
    "Philosophy",
    "Political Science",
    "Population Education",
    "Psychology",
    "Public Administration",
    "Public Relation & Advertising",
    "Rural Studies",
    "Sanskrit",
    "Sociology",
    "Vedic Studies",
    "Yoga",
)

MA_ONE_YEAR_SPECIALIZATIONS = (
    "A.I.H.C. & Archaeology",
    "Economics",
    "English",
    "Hindi",
    "Human Rights",
    "Jyotirvigyan",
    "Mass Communication",
    "Modern History",
    "Philosophy",
    "Political Science",
    "Public Administration",
    "Sanskrit",
    "Sociology",
)

MSC_SPECIALIZATIONS = (
    "Agricultural Extension & Communication",
    "Agriculture - Horticulture Fruit Science",
    "Agriculture - Plant Pathology",
    "Agriculture - Soil Science and Agricultural Chemistry",
    "Computer Science with AI & Machine Learning",
    "Biochemistry",
    "Biotechnology",
    "Botany",
    "Chemistry",
    "Computer Science",
    "Criminology",
    "Computer Science with Data Science",
    "Electronics",
    "Environment Science",
    "Forensic Science",
    "Food Technology",
    "Geography",
    "Geology",
    "Computer Science with Information Security",
    "Information Technology",
    "Mathematics",
    "Microbiology",
    "Physics",
    "Statistics",
    "Zoology",
)

MSC_ONE_YEAR_SPECIALIZATIONS = (
    "Biochemistry",
    "Biotechnology",
    "Botany",
    "Chemistry",
    "Computer Science",
    "Computer Science with Data Science",
    "Electronics",
    "Environment Science",
    "Forensic Science",
    "Food Technology",
    "Geography",
    "Geology",
    "Information Technology",
    "Mathematics",
    "Microbiology",
    "Physics",
    "Statistics",
    "Zoology",
)

CATALOG = [
    _programme("BA-H", "B.A. (Honours)", "Undergraduate and Integrated", "ARTS", 4, BA_SPECIALIZATIONS),
    _programme("BA-MA-INT", "B.A. + M.A. Integrated", "Undergraduate and Integrated", "ARTS", 5, BA_SPECIALIZATIONS),
    _programme("BBA-H-U", "B.B.A. (Honours)-U", "Undergraduate and Integrated", "MGMT", 4, (GENERAL, "Aviation Management")),
    _programme("BCA-H-U", "B.C.A. (Honours)-U", "Undergraduate and Integrated", "SCI", 4, (GENERAL,)),
    _programme("BCOM", "B.Com.", "Undergraduate and Integrated", "MGMT", 3, (GENERAL, "BFSI")),
    _programme("BCOM-H", "B.Com. (Honours)", "Undergraduate and Integrated", "MGMT", 4, (GENERAL, "Logistics", "Retail Operations")),
    _programme("BSC-H-U", "B.Sc. (Honours)-U", "Undergraduate and Integrated", "SCI", 4, BSC_SPECIALIZATIONS),
    _programme("BFA", "B. Financial Administration", "Undergraduate and Integrated", "MGMT", 3, (GENERAL,)),
    _programme("BHM", "B. Hotel Management", "Undergraduate and Integrated", "PROF", 4, (GENERAL,)),
    _programme("BMJMC", "B.MJMC", "Undergraduate and Integrated", "ARTS", 3, (GENERAL,)),
    _programme("BLIS", "B. Library Science", "Undergraduate and Integrated", "ARTS", 1, (GENERAL,)),
    _programme("BPA", "B. Performing Arts", "Undergraduate and Integrated", "ARTS", 3, (GENERAL,)),
    _programme("BPES", "B. Physical Education and Sports", "Undergraduate and Integrated", "EDU", 3, (GENERAL,)),
    _programme("MBA-INT", "Integrated MBA", "Undergraduate and Integrated", "MGMT", 5, ("BBA + MBA",)),
    _programme("BALLB-H", "B.A. LL.B. (Hons.)", "Undergraduate and Integrated", "LAW", 5, ("Law",)),
    _programme("BPHARM", "B.Pharm.", "Undergraduate and Integrated", "PHARM", 4, ("Pharmacy",)),
    _programme("BPHARM-LE", "B.Pharm. Lateral Entry", "Undergraduate and Integrated", "PHARM", 3, ("Pharmacy",)),
    _programme("BED", "B.Ed.", "Undergraduate and Integrated", "EDU", 2, ("Education",)),
    _programme("BED-SE", "B.Ed. Special Education", "Undergraduate and Integrated", "EDU", 2, ("Special Education",)),
    _programme(
        "BTECH",
        "B.Tech.",
        "Engineering - Undergraduate",
        "ENG",
        4,
        (
            "Civil Engineering",
            "Mechanical Engineering",
            "Electrical Engineering",
            "Electronics and Communication Engineering",
            "Electronics and Computer Science",
            "Agricultural Engineering",
        ),
    ),
    _programme("MA-U", "M.A.-U", "Postgraduate - Arts", "ARTS", 2, MA_SPECIALIZATIONS),
    _programme("MA-1Y-U", "M.A. (1-Year)-U", "Postgraduate - Arts", "ARTS", 1, MA_ONE_YEAR_SPECIALIZATIONS),
    _programme("MSC-U", "M.Sc.-U", "Postgraduate - Science", "SCI", 2, MSC_SPECIALIZATIONS),
    _programme("MSC-1Y-U", "M.Sc. (1-Year)-U", "Postgraduate - Science", "SCI", 1, MSC_ONE_YEAR_SPECIALIZATIONS),
    _programme(
        "MBA-U",
        "MBA-U",
        "Postgraduate - Management",
        "MGMT",
        2,
        (
            "Event Management",
            "Financial Administration",
            "Hospitality Management",
            "Human Resource Management",
            "Marketing Management",
            "Media Management",
            "Temple Management",
        ),
    ),
    _programme("MCOM", "M.Com.", "Postgraduate - Other", "MGMT", 2, (GENERAL,)),
    _programme("MCOM-U", "M.Com.-U", "Postgraduate - Other", "MGMT", 2, (GENERAL,)),
    _programme("MCA", "M.C.A.", "Postgraduate - Other", "SCI", 2, ("Computer Applications",)),
    _programme("MSW-U", "M.S.W.-U", "Postgraduate - Other", "ARTS", 2, (GENERAL,)),
    _programme("MPHARM", "M.Pharm.", "Postgraduate - Other", "PHARM", 2, ("Pharmaceutics",)),
    _programme("MPES", "M. Physical Education and Sports", "Postgraduate - Other", "EDU", 2, (GENERAL,)),
    _programme("MFA", "M.F.A.", "Postgraduate - Other", "ARTS", 2, (GENERAL,)),
    _programme("MHM", "M. Hotel Management", "Postgraduate - Other", "PROF", 2, (GENERAL,)),
    _programme("MHS", "M. Hindu Studies", "Postgraduate - Other", "ARTS", 2, (GENERAL,)),
    _programme("MJMC", "M.J.M.C.", "Postgraduate - Other", "ARTS", 2, ("1-Year", "2-Year")),
    _programme("MPA-U", "M.P.A.-U", "Postgraduate - Other", "ARTS", 2, (GENERAL,)),
    _programme("MLIS", "M. Library and Information Science", "Postgraduate - Other", "ARTS", 2, (GENERAL,)),
    _programme("LLM-U", "LL.M.-U", "Postgraduate - Other", "LAW", 2, (GENERAL, "Business Law", "Cyber Law")),
    _programme(
        "MTECH",
        "M.Tech.",
        "Engineering - Postgraduate",
        "ENG",
        2,
        (
            "Structural Engineering",
            "Thermal Engineering",
            "Power System and Automation",
            "Digital Communication",
            "IoT and Sensor Systems",
        ),
    ),
    _programme(
        "PGDCSA",
        "PGDCSA",
        "PG Diploma",
        "SCI",
        1,
        (GENERAL, "AI and Machine Learning", "Data Science", "Web Development and Software Testing"),
    ),
    _programme(
        "PHD",
        "Ph.D.",
        "Doctoral",
        "RESEARCH",
        3,
        (
            "AIHC and Archaeology",
            "Biotechnology",
            "Botany",
            "Business Management",
            "Chemistry",
            "Commerce",
            "Computer Science",
            "Continuing Education",
            "Drawing",
            "Economics",
            "Education",
            "English",
            "Environment Management",
            "Geography",
            "Geology",
            "Hindi",
            "Home Science",
            "Law",
            "Library and Information Science",
            "Mathematics",
            "Microbiology",
            "Music",
            "Pharmacy",
            "Philosophy",
            "Physics",
            "Political Science",
            "Public Administration",
            "Sanskrit",
            "Social Work",
            "Sociology",
            "Statistics",
            "Urdu",
            "Zoology",
        ),
    ),
]

CATALOG += _standalone(
    "PGD",
    (
        "PG Diploma in Agriculture Communication",
        "PG Diploma in Advanced Instrumentation Techniques",
        "PG Diploma in Archaeology",
        "PG Diploma in Astrophysics",
        "PG Diploma in Biomathematics (PGDBM)",
        "PG Diploma in Computational Linguistics (Part Time)",
        "PG Diploma in Computational Linguistics",
        "PG Diploma in Cyber Security",
        "PG Diploma in Data Analytics",
        "PG Diploma in Environment Management",
        "PG Diploma in Food Safety and Quality Control",
        "PG Diploma in Guidance and Counselling",
        "PG Diploma in Remote Sensing and GIS",
        "PG Diploma in Garbh Sanskar",
        "PG Diploma in Heritage Management",
        "PG Diploma in Information Security and Cyber Law",
        "PG Diploma in Library Automation and Networking",
        "PG Diploma in Local Governance and Political Leadership",
        "PG Diploma in Museology",
        "PG Diploma in Photography",
        "PG Diploma in Rural Development",
        "PG Diploma in Sanskrit Computational Linguistics",
        "PG Diploma in Tourism and Hotel Management",
        "PG Diploma in Translation Studies",
        "PG Diploma in Vedic Mathematics",
        "PG Diploma in Web Designing and Web Development",
        "PG Diploma in Yoga",
    ),
    "PG Diploma",
    "CONT",
)


def _strip_subject_prefix(name, prefixes):
    for prefix in prefixes:
        if name.startswith(prefix):
            return name[len(prefix):]
    return name


_pg_diploma_subjects = [
    _strip_subject_prefix(item["name"], ("PG Diploma in ",))
    for item in CATALOG
    if item["code"].startswith("PGD-")
]
_pg_diploma_subjects.insert(7, "PGDCSA")

_diploma_subjects = [
    _strip_subject_prefix(item["name"], ("Diploma in ",))
    for item in CATALOG
    if item["code"].startswith("DIP-")
]

_certificate_subjects = [
    _strip_subject_prefix(
        item["name"],
        (
            "Certificate Course in ",
            "Certificate Course on ",
            "Certificate Programme in ",
            "Certificate of ",
            "Certificate in ",
        ),
    )
    for item in CATALOG
    if item["code"].startswith("CERT-")
]

CATALOG = [
    item
    for item in CATALOG
    if not item["code"].startswith(("PGD-", "DIP-", "CERT-"))
    and item["code"] != "PGDCSA"
]
CATALOG.extend(
    [
        _programme(
            "PG-DIP",
            "PG Diploma",
            "PG Diploma",
            "CONT",
            1,
            _pg_diploma_subjects,
        ),
        _programme(
            "DIPLOMA",
            "Diploma",
            "Diploma",
            "CONT",
            1,
            _diploma_subjects,
        ),
        _programme(
            "CERTIFICATE",
            "Certificate",
            "Certificate",
            "CONT",
            1,
            _certificate_subjects,
        ),
    ]
)

_ug_codes = {
    "BA-H",
    "BA-MA-INT",
    "BBA-H-U",
    "BCA-H-U",
    "BCOM",
    "BCOM-H",
    "BSC-H-U",
    "BFA",
    "BHM",
    "BMJMC",
    "BLIS",
    "BPA",
    "BPES",
    "MBA-INT",
    "BALLB-H",
    "BPHARM",
    "BPHARM-LE",
    "BED",
    "BED-SE",
}
for item in CATALOG:
    code = item["code"]
    if code in _ug_codes:
        item["category"] = "UG & Integrated"
    elif code == "BTECH":
        item["category"] = "B.Tech"
    elif code == "MA-U":
        item["category"] = "MA-U"
    elif code == "MA-1Y-U":
        item["category"] = "MA 1 Year"
        item["name"] = "M.A. (1 Year)-U"
    elif code == "MSC-U":
        item["category"] = "MSc-U"
    elif code == "MSC-1Y-U":
        item["category"] = "MSc 1 Year"
        item["name"] = "M.Sc. (1 Year)-U"
    elif code == "MBA-U":
        item["category"] = "MBA-U"
    elif code in {
        "MCOM",
        "MCOM-U",
        "MCA",
        "MSW-U",
        "MPHARM",
        "MPES",
        "MFA",
        "MHM",
        "MHS",
        "MJMC",
        "MPA-U",
        "MLIS",
        "LLM-U",
    }:
        item["category"] = "Other PG"
    elif code == "MTECH":
        item["category"] = "M.Tech"
    elif code == "PHD":
        item["category"] = "PhD"

CATALOG += _standalone(
    "DIP",
    (
        "Diploma in Air Fare and Travel Management",
        "Diploma in Advanced Instrumentation Techniques",
        "Diploma in Airport Operation",
        "Diploma in Aviation Security",
        "Diploma in Computer Applications",
        "Diploma in Cyber Security",
        "Diploma in Data Analytics",
        "Diploma in Graphical Animated Web Designing",
        "Diploma in Dance",
        "Diploma in Fashion Designing",
        "Diploma in Instrument",
        "Diploma in Music",
        "Diploma in Theatre and Drama",
        "Diploma in Aquaculture Technology",
        "Diploma in Banking and Finance",
        "Diploma in Front Office Operation",
        "Diploma in Accounting and Taxation",
        "Diploma in Karmakanda",
        "Diploma in Russian",
        "Diploma in Information Security and Cyber Law",
        "Diploma in Industrial Safety and Occupational Health",
        "Diploma in Journalism and Mass Communication",
        "Diploma in Modern Programming Languages",
        "Diploma in Naturopathy",
        "Diploma in Tally and ERP",
        "Diploma in Web Designing and Web Development",
        "Diploma in Yoga",
        "Diploma in Yoga and Stress Management",
        "Diploma in Pharmacy (D.Pharm.)",
    ),
    "Diploma",
    "CONT",
)

CATALOG += _standalone(
    "CERT",
    (
        "Certificate in Airport Cabin Crew Training",
        "Certificate in Airline Cabin Crew",
        "Certificate in Airline Flight Load Controller",
        "Certificate in Airport Ground Staff Training",
        "Certificate in Airport Safety Crew",
        "Certificate in Advanced Yoga",
        "Certificate Course in Astrophysics",
        "Certificate Course in Aquaculture Technology",
        "Certificate in Bhartiya Gyan Parampara",
        "Certificate Course in Drone Pilot",
        "Certificate Course in Dairy Technology",
        "Certificate Course in Instrumentation Laboratory Technology",
        "Certificate in Important Rulers and Their Contribution in Indian History",
        "Certificate Course in Industrial Pollution and Wastewater Treatment Technology",
        "Certificate in Information Security and Cyber Law",
        "Certificate in Chikitsa Jyotish",
        "Certificate Course in Legal Aspects of Information Security",
        "Certificate Course in Optoelectronic Devices and Applications",
        "Certificate Course in Python Programming Language",
        "Certificate Course in Printing and Textile Chemistry",
        "Certificate Course on Research Methodology",
        "Certificate Course in Tourism Guide",
        "Certificate Course in Vermiculture Technology",
        "Certificate in Data Analytics",
        "Certificate in Flight Dispatcher",
        "Certificate in Family and Marriage Counseling",
        "Certificate in Food Preservation and Processing",
        "Certificate in Food Safety and Quality Control",
        "Certificate in Gardener Training",
        "Certificate in Computational Linguistics",
        "Certificate in Dance",
        "Certificate in Fashion Designing",
        "Certificate in Instrument",
        "Certificate in Music",
        "Certificate in Phonetics and Phonology",
        "Certificate in Theatre and Drama",
        "Certificate in Khel Patrakarita",
        "Certificate in Milk Adulteration",
        "Certificate in Mushroom Technology",
        "Certificate in Python for Analytics",
        "Certificate of Proficiency in French",
        "Certificate Programme in Ramcharitmanas - Sanskrit",
        "Certificate of Proficiency in Russian",
        "Certificate Programme in Ramcharitmanas - Vigyan",
        "Certificate in Practical Training on Analytical Instruments",
        "Certificate in Pandulipi Vigyan",
        "Certificate in Vigyan Patrakarita",
        "Certificate in Vastushastra",
    ),
    "Certificate",
    "CONT",
)

# Diploma and certificate rows are represented as parent programmes with
# selectable subjects, matching the workbook's Programme/Specialisation model.
_diploma_subjects = [
    _strip_subject_prefix(item["name"], ("Diploma in ",))
    for item in CATALOG
    if item["code"].startswith("DIP-")
]
_certificate_subjects = [
    _strip_subject_prefix(
        item["name"],
        (
            "Certificate Course in ",
            "Certificate Course on ",
            "Certificate Programme in ",
            "Certificate of ",
            "Certificate in ",
        ),
    )
    for item in CATALOG
    if item["code"].startswith("CERT-")
]
CATALOG = [
    item
    for item in CATALOG
    if not item["code"].startswith(("DIP-", "CERT-"))
    and item["code"] not in {"DIPLOMA", "CERTIFICATE"}
]
CATALOG.extend(
    [
        _programme(
            "DIPLOMA",
            "Diploma",
            "Diploma",
            "CONT",
            1,
            _diploma_subjects,
        ),
        _programme(
            "CERTIFICATE",
            "Certificate",
            "Certificate",
            "CONT",
            1,
            _certificate_subjects,
        ),
    ]
)

# -*- coding: utf-8 -*-
"""Adds the five onboarding cards' strings to all eight ARB files.

Plain insertion before the closing brace, then `json.load` to prove the file is
still a JSON object — `json.dumps` is deliberately not used, because it would
rewrite every existing key's formatting and turn a five-key diff into a 900-line
one that nobody can review.
"""
import io
import json
import os

L10N = r'C:\Users\Administrator\Documents\Default Project\salala\lib\core\l10n'

STRINGS = {
    'en': {
        'onboardingLittersTitle': 'Every litter, from mating to weaning',
        'onboardingLittersBody': 'Date the mating and Companion gives you a whelping window, not a guess. Then every puppy, its sex, its colour and its birth weight.',
        'onboardingPedigreeTitle': 'The pedigree on one page',
        'onboardingPedigreeBody': 'Sire, dam and grandparents drawn as a tree, printed beside the health record. Enough for a buyer, without paying a registry.',
        'onboardingBuyersTitle': 'Who is waiting, who has paid',
        'onboardingBuyersBody': 'Deposits, the puppy each buyer chose, the day it went home, and the signed contract filed with it.',
        'onboardingYoursTitle': "Nobody else's server",
        'onboardingYoursBody': 'No account, no ads, no tracking. Works in a shed with no signal, and your records leave the phone only when you export them.',
        'onboardingSupportTitle': 'Made by one person',
        'onboardingSupportBody': 'Companion is built by a single programmer, not a company. No ads and no investors. If it earns its place in your kennel, buying it is what keeps the updates coming.',
    },
    'ar': {
        'onboardingLittersTitle': 'كل بطن، من التلقيح إلى الفطام',
        'onboardingLittersBody': 'سجّل تاريخ التلقيح، ويعطيك Companion نافذة ولادة لا تخمينًا. ثم كل جرو، وجنسه ولونه ووزنه عند الميلاد.',
        'onboardingPedigreeTitle': 'النسب في صفحة واحدة',
        'onboardingPedigreeBody': 'الأب والأم والأجداد مرسومون شجرةً، مطبوعة بجانب تقرير الصحة. تكفي المشتري دون أن تدفع لنقابة.',
        'onboardingBuyersTitle': 'من ينتظر، ومن دفع',
        'onboardingBuyersBody': 'العربون، والجرو الذي اختاره كل مشترٍ، ويوم ذهابه إلى بيته، والعقد الموقّع محفوظًا معه.',
        'onboardingYoursTitle': 'لا خادم لأحد غيرك',
        'onboardingYoursBody': 'بلا حساب، بلا إعلانات، بلا تتبّع. يعمل في سقيفة بلا شبكة، وسجلاتك لا تغادر الهاتف إلا حين تصدّرها.',
        'onboardingSupportTitle': 'صنعه شخص واحد',
        'onboardingSupportBody': 'Companion يبنيه مبرمج واحد، لا شركة. بلا إعلانات وبلا مستثمرين. وإن وجد مكانه في مربّاك، فشراؤه هو ما يُبقي التحديثات تصل.',
    },
    'de': {
        'onboardingLittersTitle': 'Jeder Wurf, von der Deckung bis zum Absetzen',
        'onboardingLittersBody': 'Deckdatum eintragen, und Companion gibt Ihnen ein Wurffenster statt einer Schätzung. Danach jeder Welpe mit Geschlecht, Farbe und Geburtsgewicht.',
        'onboardingPedigreeTitle': 'Die Ahnentafel auf einer Seite',
        'onboardingPedigreeBody': 'Vater, Mutter und Großeltern als Baum, gedruckt neben dem Gesundheitsbericht. Genug für einen Käufer, ohne Zuchtverband.',
        'onboardingBuyersTitle': 'Wer wartet, wer gezahlt hat',
        'onboardingBuyersBody': 'Anzahlungen, der Welpe jedes Käufers, der Tag des Umzugs und der unterschriebene Vertrag dazu abgelegt.',
        'onboardingYoursTitle': 'Kein fremder Server',
        'onboardingYoursBody': 'Kein Konto, keine Werbung, kein Tracking. Läuft im Schuppen ohne Netz, und Ihre Daten verlassen das Telefon nur beim Export.',
        'onboardingSupportTitle': 'Von einer Person gebaut',
        'onboardingSupportBody': 'Companion wird von einem einzelnen Programmierer gebaut, nicht von einer Firma. Keine Werbung, keine Investoren. Wenn es seinen Platz in Ihrem Zwinger verdient, hält der Kauf die Updates am Laufen.',
    },
    'es': {
        'onboardingLittersTitle': 'Cada camada, del apareamiento al destete',
        'onboardingLittersBody': 'Anota la monta y Companion te da una ventana de parto, no una adivinanza. Después cada cachorro, su sexo, su color y su peso al nacer.',
        'onboardingPedigreeTitle': 'El pedigrí en una página',
        'onboardingPedigreeBody': 'Padre, madre y abuelos dibujados como árbol, impresos junto al historial de salud. Suficiente para un comprador, sin pagar a un registro.',
        'onboardingBuyersTitle': 'Quién espera, quién ha pagado',
        'onboardingBuyersBody': 'Señales, el cachorro que eligió cada comprador, el día que se fue a casa y el contrato firmado archivado con él.',
        'onboardingYoursTitle': 'El servidor de nadie más',
        'onboardingYoursBody': 'Sin cuenta, sin anuncios, sin rastreo. Funciona en un cobertizo sin cobertura, y tus datos solo salen del teléfono cuando los exportas.',
        'onboardingSupportTitle': 'Hecho por una persona',
        'onboardingSupportBody': 'Companion lo construye un solo programador, no una empresa. Sin anuncios y sin inversores. Si se gana su sitio en tu criadero, comprarlo es lo que mantiene las actualizaciones.',
    },
    'fr': {
        'onboardingLittersTitle': 'Chaque portée, de la saillie au sevrage',
        'onboardingLittersBody': 'Notez la saillie et Companion vous donne une fenêtre de mise bas, pas une devinette. Puis chaque chiot, son sexe, sa robe et son poids de naissance.',
        'onboardingPedigreeTitle': 'Le pédigrée sur une page',
        'onboardingPedigreeBody': 'Père, mère et grands-parents dessinés en arbre, imprimés à côté du bilan de santé. De quoi satisfaire un acheteur, sans payer un registre.',
        'onboardingBuyersTitle': 'Qui attend, qui a payé',
        'onboardingBuyersBody': 'Acomptes, le chiot choisi par chaque acheteur, le jour du départ, et le contrat signé rangé avec.',
        'onboardingYoursTitle': 'Le serveur de personne d’autre',
        'onboardingYoursBody': 'Sans compte, sans publicité, sans pistage. Fonctionne dans un cabanon sans réseau, et vos données ne quittent le téléphone que si vous exportez.',
        'onboardingSupportTitle': 'Fait par une personne',
        'onboardingSupportBody': 'Companion est construit par un seul programmeur, pas par une entreprise. Sans publicité et sans investisseurs. S’il trouve sa place dans votre élevage, l’acheter est ce qui fait vivre les mises à jour.',
    },
    'it': {
        'onboardingLittersTitle': 'Ogni cucciolata, dall’accoppiamento allo svezzamento',
        'onboardingLittersBody': 'Segna l’accoppiamento e Companion ti dà una finestra di parto, non un indovinello. Poi ogni cucciolo, sesso, mantello e peso alla nascita.',
        'onboardingPedigreeTitle': 'Il pedigree su una pagina',
        'onboardingPedigreeBody': 'Padre, madre e nonni disegnati ad albero, stampati accanto al quadro sanitario. Basta per un acquirente, senza pagare un registro.',
        'onboardingBuyersTitle': 'Chi aspetta, chi ha pagato',
        'onboardingBuyersBody': 'Caparre, il cucciolo scelto da ogni acquirente, il giorno della partenza e il contratto firmato archiviato insieme.',
        'onboardingYoursTitle': 'Il server di nessun altro',
        'onboardingYoursBody': 'Nessun account, nessuna pubblicità, nessun tracciamento. Funziona in un capanno senza rete, e i tuoi dati escono dal telefono solo quando esporti.',
        'onboardingSupportTitle': 'Fatto da una persona',
        'onboardingSupportBody': 'Companion è costruito da un solo programmatore, non da un’azienda. Nessuna pubblicità e nessun investitore. Se si guadagna il suo posto nel tuo allevamento, comprarlo è ciò che tiene in vita gli aggiornamenti.',
    },
    'nl': {
        'onboardingLittersTitle': 'Elk nest, van dekking tot spenen',
        'onboardingLittersBody': 'Leg de dekking vast en Companion geeft je een werpvenster, geen gok. Daarna elke pup, geslacht, kleur en geboortegewicht.',
        'onboardingPedigreeTitle': 'De stamboom op één pagina',
        'onboardingPedigreeBody': 'Vader, moeder en grootouders als boom getekend, afgedrukt naast het gezondheidsoverzicht. Genoeg voor een koper, zonder een stamboek te betalen.',
        'onboardingBuyersTitle': 'Wie wacht, wie heeft betaald',
        'onboardingBuyersBody': 'Aanbetalingen, de pup die elke koper koos, de dag van vertrek en het ondertekende contract erbij opgeborgen.',
        'onboardingYoursTitle': 'Niemand anders z’n server',
        'onboardingYoursBody': 'Geen account, geen advertenties, geen tracking. Werkt in een schuur zonder bereik, en je gegevens verlaten de telefoon alleen als je exporteert.',
        'onboardingSupportTitle': 'Door één persoon gemaakt',
        'onboardingSupportBody': 'Companion wordt gebouwd door één programmeur, niet door een bedrijf. Geen advertenties en geen investeerders. Als het zijn plek in je fokkerij verdient, houdt de aankoop de updates gaande.',
    },
    'pt': {
        'onboardingLittersTitle': 'Cada ninhada, do acasalamento ao desmame',
        'onboardingLittersBody': 'Registe o acasalamento e o Companion dá-lhe uma janela de parto, não um palpite. Depois cada cachorro, sexo, cor e peso à nascença.',
        'onboardingPedigreeTitle': 'O pedigree numa página',
        'onboardingPedigreeBody': 'Pai, mãe e avós desenhados em árvore, impressos ao lado do historial de saúde. Chega para um comprador, sem pagar a um registo.',
        'onboardingBuyersTitle': 'Quem espera, quem já pagou',
        'onboardingBuyersBody': 'Sinais, o cachorro que cada comprador escolheu, o dia em que foi para casa e o contrato assinado arquivado com ele.',
        'onboardingYoursTitle': 'O servidor de mais ninguém',
        'onboardingYoursBody': 'Sem conta, sem publicidade, sem rastreio. Funciona num barracão sem rede, e os seus dados só saem do telefone quando exporta.',
        'onboardingSupportTitle': 'Feito por uma pessoa',
        'onboardingSupportBody': 'O Companion é construído por um único programador, não por uma empresa. Sem publicidade e sem investidores. Se conquistar o seu lugar no seu canil, comprá-lo é o que mantém as atualizações.',
    },
}

for code, pairs in STRINGS.items():
    path = os.path.join(L10N, 'app_%s.arb' % code)
    text = io.open(path, encoding='utf-8').read()
    missing = [k for k in pairs if '"%s"' % k in text]
    if missing:
        print(code, 'already has', missing)
        continue
    body = ',\n'.join(
        '  %s: %s' % (json.dumps(k, ensure_ascii=False), json.dumps(v, ensure_ascii=False))
        for k, v in pairs.items()
    )
    cut = text.rindex('}')
    head = text[:cut].rstrip()
    if not head.endswith(','):
        head += ','
    text = head + '\n' + body + '\n}\n'
    json.loads(text)
    io.open(path, 'w', encoding='utf-8', newline='\n').write(text)
    print(code, 'added', len(pairs))

print('done')

; ============================================================================
; === Spell Checker - Auto-corrects common spelling mistakes =================
; ============================================================================

#Include ..\Lib\Core.ahk

ToggleSpellChecker() => SpellChecker.Toggle()
GetSpellCheckerState() => SpellChecker.Enabled

class SpellChecker {
    static Enabled := true

    static Toggle(state := "") {
        this.Enabled := state = "" ? !this.Enabled : state
        Info("Spell Checker " (this.Enabled ? "Enabled" : "Disabled"))
    }
}


; A
#Hotif SpellChecker.Enabled
; Nederlands Leestekens
:*:collegas::collega's
:*:colegas::collega's
:*:coordineren::coördineren
:*:eficent::efficiënt
:*:efficent::efficiënt
:*:efficient::efficiënt
:*:eficient::efficiënt
:*:financien::financiën
:*:geinteresseerd::geïnteresseerd
:*:geintereseerd::geïnteresseerd
:*:geintreseerd::geïnteresseerd
:*:geupdate::geüpdate
:*:ideeen::ideeën
:*:naief::naïef
:*:reeele::reële
:*:zeen::zeeën
:*:mn::m'n

; Nederlands
:*:alss::als
:*:aond::avond
:*:berijkt::bereikt
:*:bijvoorbeels::bijvoorbeeld
:*:dadeijk::dadelijk
:*:duideijk::duidelijk
:*:eigelijk::eigenlijk
:*:gewest::geweest
:*:iemnad::iemand
:*:konijg::koning
:*:mischien::misschien
:*:moelijk::moeilijk
:*:natuur::natuur
:*:neit::niet
:*:nieut::nieuw
:*:omdta::omdat
:*:onmiddelijk::onmiddellijk
:*:preceies::precies
:*:tegenwoordig::tegenwoordig
:*:terugh::terug
:*:tssen::tussen
:*:tusen::tussen
:*:vergetten::vergeten
:*:verschiledne::verschillende
:*:waarschijlijk::waarschijnlijk
:*:waneer::wanneer
:*:voroal::vooral
:*:waaorm::waarom
:*:zekr::zeker
; Nederlands

; English
:*:acheive::achieve
:*:acheived::achieved
:*:acheiving::achieving
:*:accomodate::accommodate
:*:acommodate::accommodate
:*:accross::across
:*:addres::address
:*:adress::address
:*:agressive::aggressive
:*:alot::a lot
:*:allready::already
:*:alright::all right
:*:amke::make
:*:anohter::another
:*:aparent::apparent
:*:appearence::appearance
:*:aquire::acquire
:*:arguement::argument
:*:aslo::also

; B
:*:becuase::because
:*:beacuse::because
:*:becasue::because
:*:beleive::believe
:*:beleif::belief
:*:breif::brief
:*:buisness::business
:*:busines::business

; C
:*:calender::calendar
:*:caluclate::calculate
:*:catagory::category
:*:cauhgt::caught
:*:changable::changeable
:*:charcteristic::characteristic
:*:cheif::chief
:*:collegue::colleague
:*:comming::coming
:*:commitee::committee
:*:commited::committed
:*:concieve::conceive
:*:consistant::consistent
:*:continous::continuous
:*:coordiate::coordinate
:*:curiousity::curiosity

; D
:*:definately::definitely
:*:definatly::definitely
:*:definitly::definitely
:*:desparate::desperate
:*:develope::develop
:*:developement::development
:*:differnce::difference
:*:diferent::different
:*:dilemna::dilemma
:*:disapear::disappear
:*:disapoint::disappoint
:*:dissapoint::disappoint

; E
:*:embarass::embarrass
:*:enviroment::environment
:*:equiped::equipped
:*:equiptment::equipment
:*:exagerate::exaggerate
:*:excede::exceed
:*:existance::existence
:*:experiance::experience
:*:expereince::experience

; F
:*:familar::familiar
:*:finaly::finally
:*:florescent::fluorescent
:*:foriegn::foreign
:*:fourty::forty
:*:foward::forward
:*:freind::friend
:*:fromt he::from the
:*:fullfil::fulfill

; G
:*:goverment::government
:*:gaurd::guard
:*:greatful::grateful
:*:guidence::guidance

; H
:*:harrass::harass
:*:happend::happened
:*:hieght::height
:*:heros::heroes
:*:higlight::highlight
:*:humerous::humorous

; I
:*:imediate::immediate
:*:imediately::immediately
:*:incidently::incidentally
:*:independant::independent
:*:indispensable::indispensable
:*:interupt::interrupt
:*:intrest::interest
:*:inot::into
:*:itneresting::interesting

; J
:*:jewellery::jewelry
:*:judgement::judgment

; K
:*:knowlege::knowledge
:*:konw::know

; L
:*:lenght::length
:*:liason::liaison
:*:libary::library
:*:lisence::license
:*:lightening::lightning
:*:liek::like
:*:likly::likely

; M
:*:maintenence::maintenance
:*:managment::management
:*:manuever::maneuver
:*:marraige::marriage
:*:medcine::medicine
:*:millenium::millennium
:*:minature::miniature
:*:mischevious::mischievous
:*:misspell::misspell
:*:momento::memento

; N
:*:neccessary::necessary
:*:necesary::necessary
:*:neice::niece
:*:noticable::noticeable
:*:occassion::occasion
:*:occured::occurred
:*:occurence::occurrence
:*:occuring::occurring

; O
:*:offical::official
:*:oging::going
:*:omision::omission
:*:oppurtunity::opportunity
:*:orignal::original

; P
:*:parrallel::parallel
:*:particularily::particularly
:*:pastime::pastime
:*:pavillion::pavilion
:*:peice::piece
:*:percieve::perceive
:*:perferred::preferred
:*:perserve::preserve
:*:persistant::persistent
:*:personell::personnel
:*:persue::pursue
:*:poeple::people
:*:posession::possession
:*:preceed::precede
:*:prefered::preferred
:*:presance::presence
:*:privelege::privilege
:*:probaly::probably
:*:proffesional::professional
:*:profesional::professional
:*:promiss::promise
:*:pronounciation::pronunciation
:*:publically::publicly

; Q
:*:questionaire::questionnaire
:*:quetion::question

; R
:*:realy::really
:*:recieve::receive
:*:recieved::received
:*:reciept::receipt
:*:reconize::recognize
:*:recomend::recommend
:*:refered::referred
:*:relavant::relevant
:*:relevent::relevant
:*:religous::religious
:*:remeber::remember
:*:repitition::repetition
:*:resistence::resistance
:*:responsability::responsibility
:*:resturant::restaurant
:*:rythm::rhythm

; S
:*:saftey::safety
:*:scedule::schedule
:*:seperate::separate
:*:sergant::sergeant
:*:shold::should
:*:sieze::seize
:*:similiar::similar
:*:simlair::similar
:*:sinceerly::sincerely
:*:skillfull::skillful
:*:soem::some
:*:speach::speech
:*:statment::statement
:*:succesful::successful
:*:supercede::supersede
:*:supress::suppress
:*:suprise::surprise
:*:surley::surely

; T
:*:taht::that
:*:teh::the
:*:themselfs::themselves
:*:thier::their
:*:thikning::thinking
:*:treshold::threshold
:*:thru::through
:*:tommorow::tomorrow
:*:tongiht::tonight
:*:truely::truly
:*:twelfth::twelfth
:*:tyrany::tyranny

; U
:*:underated::underrated
:*:untill::until
:*:unusuall::unusual
:*:upcomming::upcoming
:*:usefull::useful
:*:useing::using
:*:usualy::usually

; V
:*:vaccuum::vacuum
:*:valueable::valuable
:*:vegatarian::vegetarian
:*:vehical::vehicle
:*:visable::visible

; W
:*:watn::want
:*:wnat::want
:*:weaknes::weakness
:*:weild::wield
:*:wierd::weird
:*:wellcome::welcome
:*:wheather::weather
:*:whcih::which
:*:wich::which
:*:withint::within
:*:writting::writing

; Y
:*:yatch::yacht
:*:yeild::yield

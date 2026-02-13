#Include ..\Lib\Core.ahk

; Base
:X:\fl::Secrets.PersonalMail.Send()
:X:\fe::Secrets.FamilyMail.Send()
:X:\06::Secrets.TelNumber.Send()
:X:\adres::Secrets.Address.Send()
:X:\d::Send(FormatTime(, "dd-MM-yy"))

; Work
:X:\f::Secrets.WorkMail.Send()
:X:\b::Secrets.WorkAdminMail.Send()
:O:\r::6916009000
:O:\l0::localhost:4200
:O:\l1::localhost:4201
:O:\l2::localhost:4202
:X:\rel::Send("release/Apollo-Release-" A_Year "." A_Mon ".")

; Coding
:O:\in::{#}Include
:O:\i::{#}Include <Core>
:O:\=::; ============================================================================

; Fun
:O:\idk::¯\_(ツ)_/¯
:O:\cool::(⌐■_■)
:O:\what::ಠ_ಠ
:O:\flip::(╯°□°）╯  ┻━┻
:O:\yay::＼(＾O＾)／
:O:\lenny::( ͡° ͜ʖ ͡°)
:O:\dance::♪   ┏(･o･)┛     ┗ ( ･o･) ┓   ♪
:X:\emo::Send((emojis := ["¯\\_(ツ)_/¯", "(⌐■_■)", "ಠ_ಠ", "(╯°□°）╯  ┻━┻", "＼(＾O＾)／", "( ͡° ͜ʖ ͡°)", "♪   ┏(･o･)┛     ┗ ( ･o･) ┓   ♪"])[Random(1, emojis.Length)])
#Include <Core>
#Include <Core\SafeCall>

; Base
:X:\fl:: SafeCall("keybindings.fl", (*) => Secrets.PersonalMail.Send(), { serviceId: "key_bindings" })
:X:\fe:: SafeCall("keybindings.fe", (*) => Secrets.FamilyMail.Send(), { serviceId: "key_bindings" })
:X:\06:: SafeCall("keybindings.tel", (*) => Secrets.TelNumber.Send(), { serviceId: "key_bindings" })
:X:\adres:: SafeCall("keybindings.address", (*) => Secrets.Address.Send(), { serviceId: "key_bindings" })
:X:\d:: SafeCall("keybindings.date", (*) => Send(FormatTime(, "dd-MM-yy")), { serviceId: "key_bindings" })

; Work
:X:\f:: SafeCall("keybindings.workmail", (*) => Secrets.WorkMail.Send(), { serviceId: "key_bindings" })
:X:\f2:: SafeCall("keybindings.workmail2", (*) => Secrets.SecondWorkMail.Send(), { serviceId: "key_bindings" })
:X:\b:: SafeCall("keybindings.workadmin", (*) => Secrets.WorkAdminMail.Send(), { serviceId: "key_bindings" })
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
:X:\emo:: SafeCall("keybindings.emo", (*) => Send((emojis := ["¯\\_(ツ)_/¯", "(⌐■_■)", "ಠ_ಠ", "(╯°□°）╯  ┻━┻", "＼(＾O＾)／", "( ͡° ͜ʖ ͡°)", "♪   ┏(･o･)┛     ┗ ( ･o･) ┓   ♪"])[Random(1, emojis.Length)]), { serviceId: "key_bindings" })
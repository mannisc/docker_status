; Prototype for function pointer
Prototype.s Speak()

; Specific procedures
Procedure.s DogSpeak()
  ProcedureReturn "Woof!"
EndProcedure

Procedure.s CatSpeak()
  ProcedureReturn "Meow!"
EndProcedure

; Base "class" structure
Structure Animal
  *speak.Speak   ; Use pointer notation
EndStructure

; Create instances
Define dog.Animal
Define cat.Animal

; Assign function pointers
dog\speak = @DogSpeak()
cat\speak = @CatSpeak()

; Call them - need to dereference the pointer
Define speakFunc.Speak
speakFunc = dog\speak
Debug speakFunc()          ; Outputs "Woof!"

speakFunc = cat\speak
Debug speakFunc()          ; Outputs "Meow!"
; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 31
; Folding = -
; EnableXP
; DPIAware
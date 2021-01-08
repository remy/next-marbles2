PLUS3DOS �#   A#
 A#                                                                                                         . 
Q ;-------------------------------------------------------------------------------  ; VARIABLES  ; (3 ; %a[] - complete virtual grid of blocks and state 21 ; %c[] - collected blocks when selection is made < ; %p() - player state FQ ;------------------------------------------------------------------------------- P
 ��3     Z %p(1)=3     d %p(2)=0      n %p(6)=%1*5:; or 2 x %p(8)=%$13b2 � %p(5)=1036    �	 �reset() � �loadAssets() � �selectInput() � �replayGame() � �mainLoop() �	 �0      � �mainLoop() � %i=0      � � � �readInput() � ��="r"˓replayGame() � ��="n"˓newGame()
 ��0      � �nextLevel()" %p(9)=%p(9)+1, ; show Next Level box6 �18    ��10  
  @h ; FIXME test why the sprites aren't rendering over the layer even though it has priority on the paletteJH �126  ~  ,97  a  ,113  q  ,56  8  ,1    ,�0     ,1    ,1    T� �126  ~  -1    ,97  a  ,113  q  ,62  >  ,1    ,�0     ,1    ,1    :; put a sprite under the countdown that's solid white, just in case we hide the counter before we clear the screen^X ��126  ~  ,�,�,56  8  �61  =  ,�01100000  `  ,60  <  ,60  <  :; count down effecth �r �Ѻ|
 ��%�126=0�: �126  ~  -1    ,,,,0     :; remove the backing sprite� �� �printSeed()� �loadBlocks()� �� �selectInput()� �254  �  :�255  �  :�0     � �"assets/welcome.nxi"�� ; settings loop� �printSettings()� �start=0     � �� k$=�' �k$="1"�%p(1)=1    :�printSettings()' �k$="2"�%p(1)=2    :�printSettings()' �k$="3"�%p(1)=3    :�printSettings()& �k$="0"�start=1    0% �%�31=16�%p(1)=2    :start=1    : ��start=1    D? �%p(1)=1˓installMouse():�126  ~  ,2    ,127    ,63  ?  NG �%p(1)�1˓installInput():�127    ,96  `  ,72  H  ,63  ?  ,1    X# �%(1)=2˕125  }  ,2    ,3    b# �%(1)=3˕125  }  ,2    ,5    l �v �� �printSettings()�& ��5    ,8    ;"Select your input"� �j$(3    ,18    )� j$(1    )="1. Mouse"� j$(2    )="2. Joystick"�! j$(3    )="3. Keyboard (QAOP)"� �%i=1    �3    � j=%i�( ��%(i*2)+8,7    ;�%i=p(1    );j$(j)� �%i�	 �0     � ��%i+13,7    ;"0. START!"� � �readInput()) �%p(1)=1˓readMouse():��readJoystick():� �  �readMouse()* �126  ~  ,1    �%b,%x,%y4 �%b&@111˓selectBlock(%x,%y)> �H �readJoystick()R �125  }  ,4    ,1    \4 �12345678901234567890123456789012345678901234567890f �p �selectBlock()z	 �%p(3)˒� %p(3)=1    �> %i=%(��(127,0�99)):; which block are we over when we selected�& �%i>99�%p(3)=0     :�:; out of scope� %x=%(��(i,0)-32)�4� %y=%(��(i,1)-48)�4�# %b=%(��(i,2))-p(6):; manual offset�' �%a[i]=4�%p(3)=0     :�:; empty block�0 %c=0     :; c is the pointer in the %c[] array�6 %c[c]=-1    :; %c[] is the collected blocks taggged� �tag(%b,%x,%y)� �%c<2�%p(3)=0     :�� %p(4)=%p(4)-c� %p(2)=%p(2)+(c*(5+c))
 �50  2   �pad2(%c)�s$$ ��3    ,21    ;"CLEARED ";s$;%c$ �pad2(%p(4))�s$.' ��4    ,21    ;"REMAIN  ";s$;%p(4)8 �255  �  B �pad4(%p(2))�s$L% ��2    ,21    ;"SCORE ";s$;%p(2)VQ ; this helps me calculate the area to move blocks - which means less itterations` %z(0)=9  	  j %z(1)=0     t %z(2)=0     ~ ; remove the selected blocks� �%i=%0�%(c-1)� ;     SPRITE %c[i],,,55,� %a[c[i]]=4    � �toXY(%c[i])�%x,%y� �%x<z(0)�%z(0)=%x� �%x>z(1)�%z(1)=%x� �%y>z(2)�%z(2)=%y� ; allow UI to tick� �readInput()� �%i�	 %x=%z(0)� %z(1)=%z(1)+1 - ; marginly faster than doing a FOR x TO loop
 �:�%x�z(1)	 %y=%z(2)	 �:�%y�-1( %i=%(10*y)+x2@ �%a[i]=4˓clearColumn(%i,%x,%y):%y=0     :; IF %f THEN %y=%y+1< ; allow UI to tickF �readInput()P %y=%y-1Z
 ��0     d %x=%x+1n
 ��0     x ; now collapse the columns�	 %x=%z(0)� %z=%-1�	 �:�%x�10�	 %i=%90+x�> �%a[i]=4�%z=%x:�:�%z�-1˓shiftColumn(%x,%z):%z=%-1:%x=0     � %x=%x+1�
 ��0     � �%p(4)=0˓nextLevel()� %p(3)=0     � �� �shiftColumn(%x,%z)� %y=%0�	 �:�%y<10	 %a=%10*y %i=%a+x:; left %j=%a+z:; right"	 %a=%a[i], %a[i]=%a[j]6 �%i,,,%a[j]+p(6),@	 %a[j]=%aJ �%j,,,%a+p(6),T �readInput()^ %y=%y+1h
 ��0     r �| �clearColumn(%i,%x,%y)� �� %y=%y-1� %t=%(10*y)+x� �%y�-1:; break�- ; if we hit a block, then swap it's position� �%a[t]�4˓clearColumnSwap()� ; allow UI to tick� �readInput()�
 ��0     � �� ; mutate values� �clearColumnSwap()� ; swap the blocks at %i and %t	 %a=%a[i] %a[i]=%a[t] �%i,,,%a[t]+p(6),&	 %a[t]=%a0 �%t,,,%a+p(6),:$ ; cycle to the block directly aboveD	 %i=%i-10N �X �tag(%b,%x,%y)b �%x>9˒l �%y>9˒v %i=%(10*y)+x� �%i>99˒:; out of bounds� �%b�a[i]˒:; not a match� %j=%0� %t=%0� ; array.includes?� �� �%c��%c[j]=i�%t=%1� ; allow UI to tick� �readInput()� %j=%j+1� ��%(j�c)�(t=1)� �%t˒�	 %c[c]=%iD ; remove the sprites as we find them (so long as we find 2 or more) �%c˞%c[c],,,4    , �%c=1˞%c[0],,,4    ,  %c=%c+1* ; allow UI to tick4 �readInput()> ; now search for moreH �tag(%b,%x-1,%y)R �tag(%b,%x+1,%y)\ �tag(%b,%x,%y-1)f �tag(%b,%x,%y+1)p �z ; param {int} %i� ; returns {string} hex string� ; uses: %j, h$, r$, p� �toHex(%i)�+ %j=4    :; symbols (2 bytes = 4 symbols)� h$="0123456789abcdef"� r$=""� �:�%j�0� %j=%j-1� p=%(i&$f)+1� r$=h$(p)+r$� %i=%i�4�
 ��0     � �=r$	 �startGame(%s)	 %p(9)=1    	 %p(2)=0     	$ %p(7)=0     	. �19    �	8 �setSeed(%s)	B �loadBlocks()	L �	V �replayGame()	` �startGame(%p(8))	j �	t �newGame()	~ �startGame(%1+�$fffe)	� �	� �loadBlocks()	� %p(4)=100  d  	�
 �50  2  	�! ��3    ,21    ;"CLEARED   0"	�! ��4    ,21    ;"REMAIN  100"	� �255  �  	�! ��2    ,21    ;"SCORE     0"	� �pad4(%p(9))�s$	�% ��6    ,21    ;"LEVEL ";s$;%p(9)	� %n=0     	� �
  �pickRandom()�%r

 �toXY(%n)�%x,%y
* �%n,%(x*16)+32,%(y*16)+48,%r+p(6),0     
	 %a[n]=%r
( %n=%n+1
2	 ��%n=100
< %n=0     
F �
P �%n,,,,1    
Z %n=%n+1
d	 ��%n=100
n �
x �testRnd()
� �2    ,1    
� �
� �
�
 ��0     
� %n=0     
� �
� �pickRandom()�%r
� �%r
� %n=%n+1
�	 ��%n=100
� �
�
 �toXY(%n)
�	 %x=%n�10	 %y=%n/10 �=%x,%y �setSeed(%s)" �17    �%1,%s,	 %p(8)=%s6 �printSeed()@ �J �printSeed()T	 %s=%p(8)^ �toHex(%s)�s$h
 �50  2  r  ��7    ,21    ;"SEED  #";s$| �pad4(%p(5))�s$�% ��8    ,21    ;"BEST  ";s$;%p(5)� ��
 �pad4(%w)� �%w<10˒="    "� �%w<100˒="   "� �%w<1000˒="  "� �%w<10000˒=" "� �=""�
 �pad2(%w)� �%w<10˒="  "� �%w<100˒=" "� �=""� �onAnyKey()  ��10  
  ,21    ;"Press key"	 �:���="" �:����""�(�31    =16    )&	 �:���=""0  ��10  
  ,21    ;"         ": �D �pickRandom()No ; default seed is 1 - to change this we need to BANK #BANKRND DPOKE %1, %<16-bit> - but only during start gameX
 %r=%�17�0b �17    �%1,%rl �=%r&3v �loadAssets()� �0     :�0     :��! �"./assets/font.bin"�64000   � �B �23606  6\ ,63744   � :; 64000-256 (256 = 8 * 32 control chars)� �2    ,1    �5 ��2    :; trigger the font to be loaded on layer 2�' �"assets/over-next-level.bin"�18    �* ; shadow L2 ends at 14, so we start at 15� �"assets/marbles.pal"�15    � ��0     �15    ,0     � ��0     �15    ,0     � ; custom black and white�! �0     :�255  �  :�254  �  :�� �"assets/marbles.spr"�16     ��16    
 ��1    
 ��1     ; �23658  j\ ,0     :; turn off CAPS LOCK (for menu items)* %i=0     4 �> �%oH �17    �%i,%oR %i=%i+1\	 ��%o=201f �p	 �reset()z
 ��0     � ��� ��� ���	 �0     � �� �� �U1()� �%y� %y=%��(127,1)� �%y>1˞127    ,,%y-1,,,� �� �L1()� �%x %x=%��(127,0) �%x>1˞127    ,%x-1,,,, �$ �D1(). �%y8 %y=%��(127,1)B  �%y<(256-1)˞127    ,,%y+1,,,L �V �R1()` �%xj %x=%��(127,0)t  �%x<(320-1)˞127    ,%x+1,,,,~ �� �F1()� �selectBlock()� �� �F2()� �selectBlock()� �� �F3()� �selectBlock()� ��0 ; 16-bit xorshift pseudorandom number generator�q ; ld bc,1 : ld a,b: rra: ld a,c: rra: xor b: ld b,a: ld a,c: rra: ld a,b: rra: xor c: ld c,a: xor b: ld b,a: ret�� �1    ,1    ,0     ,120  x  ,31    ,121  y  ,31    ,168  �  ,71  G  ,121  y  ,31    ,120  x  ,31    ,169  �  ,79  O  ,168  �  ,71  G  ,201  �  :; length: 18#( �installMouse()#2 ���9030  F# #< .uninstall /nextzxos/mouse.drv#F .install /nextzxos/mouse.drv#P ��#Z �#d �installInput()#n ���9090  �# #x .uninstall assets/input.drv#� .install assets/input.drv#� ��#� �
# Introducing the myasteriskconf gem

## Usage

The most basic example illustrates registering a couple of phones.

file: myasteriskconf1.md

<pre>
# Asterisk

## SIP

externaddr: 81.110.222.62
localnet: 192.168.4.0/255.255.0.0

## Phones

C7912:1234/210
C7905:1234/220
</pre>

    require 'myasteriskconf'

    mac = MyAsteriskConf.new('/home/james/myasteriskconf1.md', debug: false)
    puts mac.to_sip

<pre>
[general]
localnet=192.168.4.0/255.255.0.0
externaddr = 81.110.222.62

[c7912]
defaultuser=c7912
secret=1234
type=friend
host=dynamic
qualify=yes
context=my-phones
insecure=invite,port
canreinvite=no
disallow=all ; better for custom-tunning codec selection
allow=ulaw
allow=alaw
allow=gsm

[c7905]
defaultuser=c7905
secret=1234
type=friend
host=dynamic
qualify=yes
context=my-phones
insecure=invite,port
canreinvite=no
disallow=all ; better for custom-tunning codec selection
allow=ulaw
allow=alaw
allow=gsm
</pre>

    puts mac.to_extensions

<pre>
[my-phones]

exten => 210,1, Answer()
exten => 210,n,Dial(SIP/C7912,40)
exten => 210,n,Hangup()

exten => 220,1, Answer()
exten => 220,n,Dial(SIP/C7905,40)
exten => 220,n,Hangup()

exten => 1009,1,Dial(SIP/c7912&SIP/c7905,40)
exten => 1009,n,Hangup()

</pre>

------------------------

In the example below, the SIP registration provider is added.

file: myasteriskconf2.md

<pre>
# Asterisk

## SIP

externaddr: 81.110.222.32
localnet: 192.168.4.0/255.255.0.0

### Register

5258619:secret@sipgate.co.uk/2012

## Phones

C7912:1234/210
C7905:1234/220

</pre>

    require 'myasteriskconf'

    mac = MyAsteriskConf.new('/home/james/myasteriskconf1.md', debug: false)
    puts mac.to_sip

<pre>
[general]
localnet=192.168.4.0/255.255.0.0
externaddr = 81.110.222.32
register => 5258619:secret@sipgate.co.uk/2012
    
[sipgate]
disable=all
type=peer
context=from-sipgate
defaultuser=5258619
fromuser=5258619
authuser=5258619
secret=secret
host=sipgate.co.uk
fromdomain=sipgate.co.uk
dtmfmode=rfc2833
insecure=invite,port
qualify=yes
canreinvite=no
nat=force_rport,comedia
disallow=all
;allow=ulaw
allow=alaw
allow=gsm
allow=g729    


[c7912]
defaultuser=c7912
secret=1234
type=friend
host=dynamic
qualify=yes
context=my-phones
insecure=invite,port
canreinvite=no
disallow=all ; better for custom-tunning codec selection
allow=ulaw
allow=alaw
allow=gsm

[c7905]
defaultuser=c7905
secret=1234
type=friend
host=dynamic
qualify=yes
context=my-phones
insecure=invite,port
canreinvite=no
disallow=all ; better for custom-tunning codec selection
allow=ulaw
allow=alaw
allow=gsm

</pre>

    puts mac.to_extensions

<pre>
[my-phones]

exten => 210,1, Answer()
exten => 210,n,Dial(SIP/C7912,40)
exten => 210,n,Hangup()

exten => 220,1, Answer()
exten => 220,n,Dial(SIP/C7905,40)
exten => 220,n,Hangup()

exten => 1009,1,Dial(SIP/c7912&SIP/c7905,40)
exten => 1009,n,Hangup()

[from-sipgate]
exten => 2012,n,Goto(my-phones,1009,1)
exten => 2012,n,Hangup()
</pre>

------------------------

In this 3rd example below, a few outbound extensions are added.

file: myasteriskconf3.md

<pre>
# Asterisk

## SIP

externaddr: 81.110.222.32
localnet: 192.168.4.0/255.255.0.0

### Register

5258619:secret@sipgate.co.uk/2012

## Phones

C7912:1234/210
C7905:1234/220

## Extensions

### Outbound

\d{6}: 0131(EXTEN)
\d{11}: (EXTEN)
999: (EXTEN)
101: (EXTEN)
9.: (EXTEN1)
</pre>

    require 'myasteriskconf'

    mac = MyAsteriskConf.new('/home/james/myasteriskconf1.md', debug: false)
    puts mac.to_sip

<pre>
[general]
localnet=192.168.4.0/255.255.0.0
externaddr = 81.110.222.32
register => 5258619:secret@sipgate.co.uk/2012
    
[sipgate]
disable=all
type=peer
context=from-sipgate
defaultuser=5258619
fromuser=5258619
authuser=5258619
secret=secret
host=sipgate.co.uk
fromdomain=sipgate.co.uk
dtmfmode=rfc2833
insecure=invite,port
qualify=yes
canreinvite=no
nat=force_rport,comedia
disallow=all
;allow=ulaw
allow=alaw
allow=gsm
allow=g729    


[c7912]
defaultuser=c7912
secret=1234
type=friend
host=dynamic
qualify=yes
context=my-phones
insecure=invite,port
canreinvite=no
disallow=all ; better for custom-tunning codec selection
allow=ulaw
allow=alaw
allow=gsm

[c7905]
defaultuser=c7905
secret=1234
type=friend
host=dynamic
qualify=yes
context=my-phones
insecure=invite,port
canreinvite=no
disallow=all ; better for custom-tunning codec selection
allow=ulaw
allow=alaw
allow=gsm

</pre>

    puts mac.to_extensions

<pre>
[my-phones]

exten => 210,1, Answer()
exten => 210,n,Dial(SIP/C7912,40)
exten => 210,n,Hangup()

exten => 220,1, Answer()
exten => 220,n,Dial(SIP/C7905,40)
exten => 220,n,Hangup()

exten => 1009,1,Dial(SIP/c7912&SIP/c7905,40)
exten => 1009,n,Hangup()

exten => _XXXXXX,1,Dial(SIP/0131${EXTEN}@sipgate,60,tr)
exten => _XXXXXX,n,Playback(invalid)
exten => _XXXXXX,n,Hangup

exten => _XXXXXXXXXXX,1,Dial(SIP/${EXTEN}@sipgate,60,tr)
exten => _XXXXXXXXXXX,n,Playback(invalid)
exten => _XXXXXXXXXXX,n,Hangup

exten => 999,1,Dial(SIP/${EXTEN}@sipgate,60,tr)
exten => 999,n,Playback(invalid)
exten => 999,n,Hangup

exten => 101,1,Dial(SIP/${EXTEN}@sipgate,60,tr)
exten => 101,n,Playback(invalid)
exten => 101,n,Hangup

exten => _9.,1,Dial(SIP/(EXTEN1)@sipgate,60,tr)
exten => _9.,n,Playback(invalid)
exten => _9.,n,Hangup

[from-sipgate]
exten => 2012,n,Goto(my-phones,1009,1)
exten => 2012,n,Hangup()
</pre>

## Resources

* myasteriskconf https://rubygems.org/gems/myasteriskconf

asterisk sipgate config conf configuration

#!/usr/bin/env ruby

# file: myasteriskconf.rb

require 'polyrex-headings'


class MyAsteriskConf
  using ColouredText

  attr_reader :to_h

  def initialize(raw_s, debug: false)

    @debug = debug

    contents = RXFHelper.read(raw_s).first
    puts 'content: ' + contents.inspect if @debug

    s = if contents =~ /^<\?ph / then
      contents
    else
'<?ph schema="sections[title,tags]/section[x]"?>
title: Asterisk Config
tags: asterisk    

' + contents

    end

    puts ('s: ' + s.inspect).debug if @debug
    ph = PolyrexHeadings.new(s, debug: debug) 
    
    @to_h = @h = ph.to_h.first.last
    puts @to_h.inspect

    @sip = []
    @extensions = []
    build()

  end

  def to_extensions()
    @extensions.join("\n")
  end

  def to_sip()
    @sip.join("\n")
  end

  private

  def build(default_ctx='my-phones')

    puts 'h: ' + @h.inspect if @debug
    @sip << "[general]"
    
    if @h[:sip][:localnet] then
      
      localnet = if @h[:sip][:localnet].length < 2 then
        localnet()
      else
        @h[:sip][:localnet]
      end
      
      @sip << "localnet=" + localnet
      
    end

    
    if @h[:sip][:externaddr] then
      
      externaddr = if @h[:sip][:externaddr].length < 2 then
        externaddr()
      else
        @h[:sip][:externaddr]
      end
      
      @sip << "externaddr=" + externaddr
      
    end
    
    
    if @h[:sip][:context] then
      
      localnet = if @h[:sip][:context].length < 2 then
        'default'
      else
        @h[:sip][:context]
      end
      
      @sip << "context=" + context
      
    end    
         
    
    registers = @h.dig(*%i(sip register))
    register = nil
    
    if registers and registers.any? then
      
      register = registers.first
      userid, reg_secret, sip_host = register.match(/(\w+):(\w+)@([^\/]+)/)\
          .captures
      reg_label = sip_host[/\w+/]


      @sip << "register => " + register
    
      reg_label = register[/(?<=@)\w+/]
      @sip << sip_provider_template(reg_label, userid, reg_secret, sip_host)
      
    end
    
    extensions = {default_ctx => []}

    phones = @h[:phones].map do |x|

      puts 'x: ' + x.inspect if @debug      
      
      regex = %r{

        (?<id>[^:]+){0}
        (?<secret>[^\/]+){0}
        (?<ext>[^@$]+){0}
        (?:@(?<context>[^$]+)){0}

      ^\g<id>:\g<secret>(?:\/)?\g<ext>?\g<context>?
      }x

      r = regex.match(x)      
      r.named_captures.values
      
    end
    
    puts 'phones: ' + phones.inspect if @debug
    
    phones.each do |id, secret, ext, context|

      ctx = context || default_ctx      
      @sip << sip_template(id.downcase, secret, ctx)

      puts 'ctx: '  + ctx.inspect if @debug
      puts 'extensions: ' + extensions.inspect if @debug
      
      extensions[ctx] ||= []
      extensions[ctx] << ext_template(ext, id)

    end

    extensions.map do |key, value|
      
      context = key
      entries = value
      @extensions << "\n[#{context}]"
      @extensions.concat entries
      @extensions << "\n"
      
    end
    
    a = phones.map {|x| "SIP/" + x[0].downcase }
    @extensions << "\nexten => 1009,1,Dial(%s,40)" % a.join('&')
    @extensions << "exten => 1009,n,Hangup()"
    
    # check for outbound extensions
    
    outbound = @h.dig(*%i(extensions outbound))
    
=begin
Pattern matching help for variable extension numbers:

- X - any digit from 0-9
- Z - any digit from 1-9
- N - any digit from 2-9
- [12679] - any digit in the brakets (in the example: 1,2,6,7,9)
- . - (dot) wildcard, matches everything remaining
( _1234. - matches anything strating with 1234 excluding 1234 itself).

source: https://www.asteriskguru.com/tutorials/extensions_conf.html
=end
    if outbound then
      
      outbound.each do |key, value|

        r = key[/d\{(\d+)\}/,1]

        dialout = value.sub(/\(EXTEN\)/,'${EXTEN}')      
        
        if r then
        
          pattern = '_' + 'X' * r.to_i
          
        elsif key[/^\d+$/]
          
          pattern = key.to_s
          
        else
          
          dialout = value.sub(/\((EXTEN:?1?)\)/,'${\1}')      
          pattern = '_' + key.to_s        
          
        end      
        
        @extensions << "\nexten => %s,1,Dial(SIP/%s@%s,60,tr)" \
            % [pattern, dialout, reg_label]
        @extensions << "exten => %s,n,Playback(invalid)" % pattern
        @extensions << "exten => %s,n,Hangup" % pattern      
        
      end
      
    end
    
    if register then
      
      @extensions << "\n[from-#{reg_label}]"
      reg_ext = register[/\d+$/]
      @extensions << "exten => #{reg_ext},n,Goto(my-phones,1009,1)"
      @extensions << "exten => #{reg_ext},n,Hangup()"
      
    end    

  end

  def ext_template(ext, deviceid)

"
exten => #{ext},1, Answer()
exten => #{ext},n,Dial(SIP/#{deviceid},40)
exten => #{ext},n,Hangup()"

  end
  
  def externaddr()
    h = JSON.parse open('http://jsonip.com/').read
    h['ip']    
  end
  
  def sip_provider_template(reg_label, userid, reg_secret, sip_host)
    
"    
[#{reg_label}]
disable=all
type=peer
context=from-#{reg_label}
defaultuser=#{userid}
fromuser=#{userid}
authuser=#{userid}
secret=#{reg_secret}
host=#{sip_host}
fromdomain=#{sip_host}
dtmfmode=rfc2833
insecure=invite,port
qualify=yes
canreinvite=no
nat=force_rport,comedia
disallow=all
;allow=ulaw
allow=alaw
allow=gsm
allow=g729"   

  end
  
  def localnet()
    r = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }
    r.ip_address.sub(/\d+$/,'0')
  end


  def sip_template(deviceid, secret, context='my-phones')

"
[#{deviceid}]
defaultuser=#{deviceid}
secret=#{secret}
type=friend
host=dynamic
qualify=yes
context=#{context}
insecure=invite,port
canreinvite=no
disallow=all ; better for custom-tunning codec selection
allow=ulaw
allow=alaw
allow=gsm"

  end

end

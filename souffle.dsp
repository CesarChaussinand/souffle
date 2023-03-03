import("stdfaust.lib");
import("synreson.lib");

process = bass, kick(normGate2*(1-(block>14))), bell, arp :> fx(Rate,fdbk),fx(-Rate,fdbk);

arp = (_*0.7)+synreson(fr,amp)*0.1, (_*0.7)+synreson(fr,amp)*0.1 : eko with{
    eko = ef.echo(60/Tempo,60/Tempo,0.7),ef.echo(60/Tempo,60/Tempo,0.7);
    amp = trig:en.ar(0.01,0.2)*arpGate;
    arpGate = ((block>1) * (block<6)) + ((block>12) * (block<15));
    fr = ba.midikey2hz(sequence(trig));
    sequence(t) = ba.selectn(12,ba.counter(t)%12, 88,91,95,88,93,96,88,91,95,87,89,95);
    trig =  ((bar%2)==0)*(clock!=clock')*ba.selectn(16,clock,list);
    list = 1,0,0,1, 0,0,1,0, 0,0,0,0, 0,0,0,0;
};

fx(r,fb) = fi.fb_comb (1024,(os.osc(r)*d)+d+60,1,fb):ef.cubicnl(0,0)*1.2 with{
    d=60;
};

Rate = 0.2;
fdbk = sqrt(max(1:en.adsr(5,3,0.5,0.01)-0.2,0));

bass = os.sawtooth(fr) :fi.resonlp(frcut,3,vol):ef.cubicnl(0,0) <:_,_ with {
    fr = 28:ba.midikey2hz;
    frcut = 150 + env*50;
    vol = env*0.9*sequence(trig) + 0.2;
    env = (trig*(1-(block>14))):en.ar(0.001,0.2);
    trig = (clock!=clock')*ba.selectn(16,clock%16, list);
    list = 1,0,1,1, 0,0,1,0, 1,0,1,1, 0,0,1,0 ;
    sequence(t) = ba.selectn(8,ba.counter(t)%8, 1,0.1,0.5,0.8, 1,0,0.4,0.7); //t : trigger
};

gate = ba.counter(1-(bar==bar'))>13;
normGate = gate;
normGateInt = normGate' : ba.latch(clock<clock');
normGate2 = normGateInt' : ba.latch(clock<clock');

bell = pre, post :> _,_ with{
    pre = (synth(fr,vol)+synth(fr+50,vol))*(1+lfo), 
            (synth(fr,vol)+synth(fr+50,vol))*(1-lfo) with{
        synth(f,v)=os.triangle(f)*v,
                    os.triangle(f*3/2)*v*0.8,
                        os.triangle(f*5/2)*v*0.5:>_/5;
        fr = 1200+lfo*10;
        vol = max(env*0.7-0.1,0);
        env = ((normGate*(normGate!=normGate2))+end):en.asr(4.2,1,0.001);
        end = (ba.counter(1-(bar==bar'))>56) * (ba.counter(1-(bar==bar'))<60);
        lfo = os.osc(lf*20)*0.7*env;
        lf = (env)^2; 
        step = clock:ba.latch(normGate>normGate');
    };
    post = normGate2:en.ar(0.002,0.002)*no.noise : pm.englishBell(1,2400,0.75,1) <:_,_;
};

kick(amp) = env*os.osc(80*env+30) : ef.cubicnl(0.1,0) * amp <: _,_ with{
    env = trig:en.ar(0.001,0.2);
    trig = (clock!=clock')*ba.selectn(16,clock,list);
    list = 1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,bar%2==1,0;
};

block = ba.counter(bar<bar') <:attach(_,_+1:hbargraph("boucle",1,32));
bar = ba.counter(clock<clock')%4 <:attach(_,_+1:hbargraph("mesure",1,4));
clock = os.phasor(16,Tempo/(60*4)):int <:attach(_,int(_/4)+1:hbargraph("temps",1,4));
Tempo = 110;

# Embraer e-Jet 195 systems
# 
# Syd Adams
#

aircraft.livery.init("Aircraft/Embraer-195/Models/Liveries");
var SndOut = props.globals.getNode("/sim/sound/Ovolume",1);
var FHmeter = aircraft.timer.new("/instrumentation/clock/flight-meter-sec", 10).stop();
var fuel_density =0;


#EFIS specific class
# ie: var efis = EFIS.new("instrumentation/EFIS");
var EFIS = {
    new : func(prop1){
        m = { parents : [EFIS]};
        m.radio_list=["instrumentation/comm/frequencies","instrumentation/comm[1]/frequencies","instrumentation/nav/frequencies","instrumentation/nav[1]/frequencies"];
        m.mfd_mode_list=["APP","VOR","MAP","PLAN"];
        m.eicas_msg=[];
        m.eicas_msg_red=[];
        m.eicas_msg_green=[];
        m.eicas_msg_blue=[];
        m.eicas_msg_alpha=[];

        m.efis = props.globals.initNode(prop1);
        m.mfd = m.efis.initNode("mfd");
        m.pfd = m.efis.initNode("pfd");
        m.eicas = m.efis.initNode("eicas");
        m.mfd_mode_num = m.mfd.initNode("mode-num",2,"INT");
        m.mfd_display_mode = m.mfd.initNode("display-mode",m.mfd_mode_list[2]);
        m.kpa_mode = m.efis.initNode("inputs/kpa-mode",0,"BOOL");
        m.kpa_output = m.efis.initNode("inhg-kpa",29.92);
        m.temp = m.efis.initNode("fixed-temp",0);
        m.alt_meters = m.efis.initNode("inputs/alt-meters",0,"BOOL");
        m.fpv = m.efis.initNode("inputs/fpv",0,"BOOL");
        m.nd_centered = m.efis.initNode("inputs/nd-centered",0,"BOOL");
        m.mins_mode = m.efis.initNode("inputs/minimums-mode",0,"BOOL");
        m.minimums = m.efis.initNode("minimums",200,"INT");
        m.mk_minimums = props.globals.getNode("instrumentation/mk-viii/inputs/arinc429/decision-height");
        m.wxr = m.efis.initNode("inputs/wxr",0,"BOOL");
        m.range = m.efis.initNode("inputs/range",0);
        m.sta = m.efis.initNode("inputs/sta",0,"BOOL");
        m.wpt = m.efis.initNode("inputs/wpt",0,"BOOL");
        m.arpt = m.efis.initNode("inputs/arpt",0,"BOOL");
        m.data = m.efis.initNode("inputs/data",0,"BOOL");
        m.pos = m.efis.initNode("inputs/pos",0,"BOOL");
        m.terr = m.efis.initNode("inputs/terr",0,"BOOL");
        m.rh_vor_adf = m.efis.initNode("inputs/rh-vor-adf",0,"INT");
        m.lh_vor_adf = m.efis.initNode("inputs/lh-vor-adf",0,"INT");

        m.radio = m.efis.getNode("radio-mode",1);
        m.radio.setIntValue(0);
        m.radio_selected = m.efis.getNode("radio-selected",1);
        m.radio_selected.setDoubleValue(getprop("instrumentation/comm/frequencies/selected-mhz"));
        m.radio_standby = m.efis.getNode("radio-standby",1);
        m.radio_standby.setDoubleValue(getprop("instrumentation/comm/frequencies/standby-mhz"));

        m.kpaL = setlistener("instrumentation/altimeter/setting-inhg", func m.calc_kpa());

        for(var i=0; i<11; i+=1) {
        append(m.eicas_msg,m.eicas.initNode("msg["~i~"]/text"," ","STRING"));
        append(m.eicas_msg_red,m.eicas.initNode("msg["~i~"]/red",0.1 *i));
        append(m.eicas_msg_green,m.eicas.initNode("msg["~i~"]/green",0.8));
        append(m.eicas_msg_blue,m.eicas.initNode("msg["~i~"]/blue",0.8));
        append(m.eicas_msg_alpha,m.eicas.initNode("msg["~i~"]/alpha",1.0));
        }

    return m;
    },
#### convert inhg to kpa ####
    calc_kpa : func{
        var kp = getprop("instrumentation/altimeter/setting-inhg");
        kp= kp * 33.8637526;
        me.kpa_output.setValue(kp);
        },
#### update temperature display ####
    update_temp : func{
        var tmp = getprop("/environment/temperature-degc");
        if(tmp < 0.00){
            tmp = -1 * tmp;
        }
        me.temp.setValue(tmp);
    },
#### swap radio freq ####
    swap_freq : func(){
        var tmpsel = me.radio_selected.getValue();
        var tmpstb = me.radio_standby.getValue();
        me.radio_selected.setValue(tmpstb);
        me.radio_standby.setValue(tmpsel);
        me.update_frequencies();
    },
#### copy efis freq to radios ####
    update_frequencies : func(){
        var fq = me.radio.getValue();
        setprop(me.radio_list[fq]~"/selected-mhz",me.radio_selected.getValue());
        setprop(me.radio_list[fq]~"/standby-mhz",me.radio_standby.getValue());
    },
#### modify efis radio standby freq ####
    set_freq : func(fdr){
        var rd = me.radio.getValue();
        var frq =me.radio_standby.getValue();
        var frq_step =0;
        if(rd >=2){
            if(fdr ==1)frq_step = 0.05;
            if(fdr ==-1)frq_step = -0.05;
            if(fdr ==10)frq_step = 1.0;
            if(fdr ==-10)frq_step = -1.0;
            frq += frq_step;
            if(frq > 118.000)frq -= 10.000;
            if(frq<108.000) frq += 10.000;
        }else{
            if(fdr ==1)frq_step = 0.025;
            if(fdr ==-1)frq_step = -0.025;
            if(fdr ==10)frq_step = 1.0;
            if(fdr ==-10)frq_step = -1.0;
            frq += frq_step;
            if(frq > 136.000)frq -= 18.000;
            if(frq<118.000) frq += 18.000;
        }
        me.radio_standby.setValue(frq);
        me.update_frequencies();
    },

    set_radio_mode : func(rm){
        me.radio.setIntValue(rm);
        me.radio_selected.setDoubleValue(getprop(me.radio_list[rm]~"/selected-mhz"));
        me.radio_standby.setDoubleValue(getprop(me.radio_list[rm]~"/standby-mhz"));
    },
######### Controller buttons ##########
    ctl_func : func(md,val){
        if(md=="range")
        {
            var rng =getprop("instrumentation/radar/range");
            if(val ==1){
                rng =rng * 2;
                if(rng > 640) rng = 640;
            }elsif(val =-1){
                rng =rng / 2;
                if(rng < 10) rng = 10;
            }
            setprop("instrumentation/radar/range",rng);
            me.range.setValue(rng);
        }
        elsif(md=="tfc")
        {
            var pos =getprop("instrumentation/radar/switch");
            if(pos == "on"){
                pos = "off";
                
            }else{
                pos="on";
            }
            setprop("instrumentation/radar/switch",pos);
        }
        elsif(md=="dh")
        {
            var num =me.minimums.getValue();
            if(val==0){
                num=200;
            }else{
                num+=val;
                if(num<0)num=0;
                if(num>1000)num=1000;
            }
        me.minimums.setValue(num);
        me.mk_minimums.setValue(num);
        }
        elsif(md=="display")
        {
            var num =me.mfd_mode_num.getValue();
            num+=val;
            if(num<0)num=0;
            if(num>3)num=3;
            me.mfd_mode_num.setValue(num);
            me.mfd_display_mode.setValue(me.mfd_mode_list[num]);
        }
        elsif(md=="terr")
        {
            var num =me.terr.getValue();
            num=1-num;
            me.terr.setValue(num);
        }
        elsif(md=="arpt")
        {
            var num =me.arpt.getValue();
            num=1-num;
            me.arpt.setValue(num);
        }
        elsif(md=="wpt")
        {
            var num =me.wpt.getValue();
            num=1-num;
            me.wpt.setValue(num);
        }
        elsif(md=="sta")
        {
            var num =me.sta.getValue();
            num=1-num;
            me.sta.setValue(num);
        }
        elsif(md=="wxr")
        {
            var num =me.wxr.getValue();
            num=1-num;
            me.wxr.setValue(num);
        }
        elsif(md=="rhvor")
        {
            var num =me.rh_vor_adf.getValue();
            num+=val;
            if(num>1)num=1;
            if(num<-1)num=-1;
            me.rh_vor_adf.setValue(num);
        }
        elsif(md=="lhvor")
        {
            var num =me.lh_vor_adf.getValue();
            num+=val;
            if(num>1)num=1;
            if(num<-1)num=-1;
            me.lh_vor_adf.setValue(num);
        }
        elsif(md=="center")
        {
            var num =me.nd_centered.getValue();
            var fnt=[5,8];
            num = 1 - num;
            me.nd_centered.setValue(num);
            setprop("instrumentation/radar/font/size",fnt[num]);
        }
    },
};
##############################################
##############################################
#Engine control class
# ie: var Eng = Engine.new(engine number);
var Engine = {
    new : func(eng_num){
        m = { parents : [Engine]};
        m.fdensity = getprop("consumables/fuel/tank/density-ppg");
        if(m.fdensity ==nil)m.fdensity=6.72;
        m.eng = props.globals.getNode("engines/engine["~eng_num~"]",1);
        m.running = m.eng.getNode("running",1);
        m.running.setBoolValue(0);
        m.n1 = m.eng.getNode("n1",1);
        m.n2 = m.eng.getNode("n2",1);
        m.rpm = m.eng.getNode("rpm",1);
        m.rpm.setDoubleValue(0);
        m.throttle_lever = props.globals.getNode("controls/engines/engine["~eng_num~"]/throttle-lever",1);
        m.throttle_lever.setDoubleValue(0);
        m.throttle = props.globals.getNode("controls/engines/engine["~eng_num~"]/throttle",1);
        m.throttle.setDoubleValue(0);
        m.cutoff = props.globals.getNode("controls/engines/engine["~eng_num~"]/cutoff",1);
        m.cutoff.setBoolValue(1);
        m.fuel_out = props.globals.getNode("engines/engine["~eng_num~"]/out-of-fuel",1);
        m.fuel_out.setBoolValue(0);
        m.starter = props.globals.getNode("controls/engines/engine["~eng_num~"]/starter",1);
        m.fuel_pph=m.eng.getNode("fuel-flow_pph",1);
        m.fuel_pph.setDoubleValue(0);
        m.fuel_gph=m.eng.getNode("fuel-flow-gph",1);
        m.hpump=props.globals.getNode("systems/hydraulics/pump-psi["~eng_num~"]",1);
        m.hpump.setDoubleValue(0);
    return m;
    },
#### update ####
    update : func{
        if(me.fuel_out.getBoolValue())me.cutoff.setBoolValue(1);
        if(!me.cutoff.getBoolValue()){
        me.rpm.setValue(me.n1.getValue());
        me.throttle_lever.setValue(me.throttle.getValue());
        }else{
            me.throttle_lever.setValue(0);
            if(me.starter.getBoolValue()){
                me.spool_up();
            }else{
                var tmprpm = me.rpm.getValue();
                if(tmprpm > 0.0){
                    tmprpm -= getprop("sim/time/delta-realtime-sec") * 0.5;
                    me.rpm.setValue(tmprpm);
                }
            }
        }
    me.fuel_pph.setValue(me.fuel_gph.getValue()*me.fdensity);
    var hpsi =me.rpm.getValue();
    if(hpsi>60)hpsi = 60;
    me.hpump.setValue(hpsi);
    },

    spool_up : func{
        if(!me.cutoff.getBoolValue()){
        return;
        }else{
            var tmprpm = me.rpm.getValue();
            tmprpm += getprop("sim/time/delta-realtime-sec") * 0.5;
            me.rpm.setValue(tmprpm);
            if(tmprpm >= me.n1.getValue())me.cutoff.setBoolValue(0);
        }
    },

};
##########################

var Wiper = {
    new : func {
        m = { parents : [Wiper] };
        m.direction = 0;
        m.delay_count = 0;
        m.spd_factor = 0;
        m.node = props.globals.getNode(arg[0],1);
        m.power = props.globals.getNode(arg[1],1);
        if(m.power.getValue()==nil)m.power.setDoubleValue(0);
        m.spd = m.node.getNode("arc-sec",1);
        if(m.spd.getValue()==nil)m.spd.setDoubleValue(1);
        m.delay = m.node.getNode("delay-sec",1);
        if(m.delay.getValue()==nil)m.delay.setDoubleValue(0);
        m.position = m.node.getNode("position-norm", 1);
        m.position.setDoubleValue(0);
        m.switch = m.node.getNode("switch", 1);
        if (m.switch.getValue() == nil)m.switch.setBoolValue(0);
        return m;
    },
    active: func{
    if(me.power.getValue()<=5)return;
    var spd_factor = 1/me.spd.getValue();
    var pos = me.position.getValue();
    if(!me.switch.getValue()){
        if(pos <= 0.000)return;
        }
    if(pos >=1.000){
        me.direction=-1;
        }elsif(pos <=0.000){
        me.direction=0;
        me.delay_count+=getprop("/sim/time/delta-sec");
        if(me.delay_count >= me.delay.getValue()){
            me.delay_count=0;
            me.direction=1;
            }
        }
    var wiper_time = spd_factor*getprop("/sim/time/delta-sec");
    pos +=(wiper_time * me.direction);
    me.position.setValue(pos);
    }
};
#####################

var Efis = EFIS.new("instrumentation/efis");
var LHeng=Engine.new(0);
var RHeng=Engine.new(1);
    var wiper = Wiper.new("controls/electric/wipers","systems/electrical/bus-volts");

setlistener("/sim/signals/fdm-initialized", func {
    SndOut.setDoubleValue(0.15);
    setprop("/instrumentation/clock/flight-meter-hour",0);
    setprop("/instrumentation/groundradar/id",getprop("sim/tower/airport-id"));
    settimer(update_systems,2);
});

setlistener("/sim/signals/reinit", func {
    SndOut.setDoubleValue(0.15);
    setprop("/instrumentation/clock/flight-meter-hour",0);
    Shutdown();
});

setlistener("/autopilot/route-manager/route/num", func(wp){
    var wpt= wp.getValue() -1;

    if(wpt>-1){
    setprop("instrumentation/groundradar/id",getprop("autopilot/route-manager/route/wp["~wpt~"]/id"));
    }else{
    setprop("instrumentation/groundradar/id",getprop("sim/tower/airport-id"));
    }
},1,0);

setlistener("/sim/current-view/internal", func(vw){
    if(vw.getValue()){
    SndOut.setDoubleValue(0.3);
    }else{
    SndOut.setDoubleValue(1.0);
    }
},1,0);

setlistener("/sim/model/start-idling", func(idle){
    var run= idle.getBoolValue();
    if(run){
    Startup();
    }else{
    Shutdown();
    }
},0,0);

controls.gearDown = func(v) {
    if (v < 0) {
        if(!getprop("gear/gear[1]/wow"))setprop("/controls/gear/gear-down", 0);
    } elsif (v > 0) {
      setprop("/controls/gear/gear-down", 1);
    }
}

stall_horn = func{
    var alert=0;
    var kias=getprop("velocities/airspeed-kt");
    if(kias>150){setprop("sim/sound/stall-horn",alert);return;};
    var wow1=getprop("gear/gear[1]/wow");
    var wow2=getprop("gear/gear[2]/wow");
    if(!wow1 or !wow2){
        var grdn=getprop("controls/gear/gear-down");
        var flap=getprop("controls/flight/flaps");
        if(kias<100){
            alert=1;
        }elsif(kias<120){
            if(!grdn )alert=1;
        }else{
            if(flap==0)alert=1;
        }
    }
    setprop("sim/sound/stall-horn",alert);
}

var Startup = func{
setprop("controls/electric/engine[0]/generator",1);
setprop("controls/electric/engine[1]/generator",1);
setprop("controls/electric/engine[0]/bus-tie",1);
setprop("controls/electric/engine[1]/bus-tie",1);
setprop("controls/electric/APU-generator",1);
setprop("controls/electric/avionics-switch",1);
setprop("controls/electric/battery-switch",1);
setprop("controls/electric/inverter-switch",1);
setprop("controls/lighting/instrument-norm",0.8);
setprop("controls/lighting/nav-lights",1);
setprop("controls/lighting/beacon",1);
setprop("controls/lighting/strobe",1);
setprop("controls/lighting/wing-lights",1);
setprop("controls/lighting/taxi-lights",1);
setprop("controls/lighting/logo-lights",1);
setprop("controls/lighting/cabin-lights",1);
setprop("controls/lighting/landing-light[0]",1);
setprop("controls/lighting/landing-light[1]",1);
setprop("controls/lighting/landing-light[2]",1);
setprop("controls/engines/engine[0]/cutoff",0);
setprop("controls/engines/engine[1]/cutoff",0);
setprop("controls/fuel/tank/boost-pump",1);
setprop("controls/fuel/tank/boost-pump[1]",1);
setprop("controls/fuel/tank[1]/boost-pump",1);
setprop("controls/fuel/tank[1]/boost-pump[1]",1);
setprop("controls/fuel/tank[2]/boost-pump",1);
setprop("controls/fuel/tank[2]/boost-pump[1]",1);
}

var Shutdown = func{
setprop("controls/electric/engine[0]/generator",0);
setprop("controls/electric/engine[1]/generator",0);
setprop("controls/electric/engine[0]/bus-tie",0);
setprop("controls/electric/engine[1]/bus-tie",0);
setprop("controls/electric/APU-generator",0);
setprop("controls/electric/avionics-switch",0);
setprop("controls/electric/battery-switch",0);
setprop("controls/electric/inverter-switch",0);
setprop("controls/lighting/instruments-norm",0);
setprop("controls/lighting/nav-lights",0);
setprop("controls/lighting/beacon",0);
setprop("controls/lighting/strobe",0);
setprop("controls/lighting/wing-lights",0);
setprop("controls/lighting/taxi-lights",0);
setprop("controls/lighting/logo-lights",0);
setprop("controls/lighting/cabin-lights",0);
setprop("controls/lighting/landing-light[0]",0);
setprop("controls/lighting/landing-light[1]",0);
setprop("controls/lighting/landing-light[2]",0);
setprop("controls/engines/engine[0]/cutoff",1);
setprop("controls/engines/engine[1]/cutoff",1);
setprop("controls/fuel/tank/boost-pump",0);
setprop("controls/fuel/tank/boost-pump[1]",0);
setprop("controls/fuel/tank[1]/boost-pump",0);
setprop("controls/fuel/tank[1]/boost-pump[1]",0);
setprop("controls/fuel/tank[2]/boost-pump",0);
setprop("controls/fuel/tank[2]/boost-pump[1]",0);
}

var update_systems = func {
    Efis.calc_kpa();
    Efis.update_temp();
    LHeng.update();
    RHeng.update();
    wiper.active();
    stall_horn();
    settimer(update_systems,0);
}

####    2 Generator Jet Electrical system    #### 
####    Liam Gathercole    ####
#### Based on Curtis Olson's nasal electrical code ####

var count=0;
var ammeter_ave = 0.0;
var Lbus = props.globals.initNode("/systems/electrical/left-bus",0,"DOUBLE");
var Rbus = props.globals.initNode("/systems/electrical/right-bus",0,"DOUBLE");
var Amps = props.globals.initNode("/systems/electrical/amps",0,"DOUBLE");
var EXT  = props.globals.initNode("/controls/electric/external-power",0,"DOUBLE");
var XTie  = props.globals.initNode("/systems/electrical/xtie",0,"BOOL");
var lbus_volts = 0.0;
var rbus_volts = 0.0;

var lbus_input=[];
var lbus_output=[];
var lbus_load=[];

var rbus_input=[];
var rbus_output=[];
var rbus_load=[];

var lights_input=[];
var lights_output=[];
var lights_load=[];

var strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("controls/lighting/strobe-state", [0.05, 1.30], strobe_switch);
var beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("controls/lighting/beacon-state", [1.0, 1.0], beacon_switch);

#var battery = Battery.new(switch-prop,volts,amps,amp_hours,charge_percent,charge_amps);
var Battery = {
    new : func(swtch,vlt,amp,hr,chp,cha){
    m = { parents : [Battery] };
            m.switch = props.globals.getNode(swtch,1);
            m.switch.setBoolValue(0);
            m.ideal_volts = vlt;
            m.ideal_amps = amp;
            m.amp_hours = hr;
            m.charge_percent = chp;
            m.charge_amps = cha;
    return m;
    },

    apply_load : func(load,dt) {
        if(me.switch.getValue()){
        var amphrs_used = load * dt / 3600.0;
        var percent_used = amphrs_used / me.amp_hours;
        me.charge_percent -= percent_used;
        if ( me.charge_percent < 0.0 ) {
            me.charge_percent = 0.0;
        } elsif ( me.charge_percent > 1.0 ) {
        me.charge_percent = 1.0;
        }
        var output =me.amp_hours * me.charge_percent;
        return output;
        }else return 0;
    },

    get_output_volts : func {
        if(me.switch.getValue()){
        var x = 1.0 - me.charge_percent;
        var tmp = -(3.0 * x - 1.0);
        var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
        var output =me.ideal_volts * factor;
        return output;
        }else return 0;
    },

    get_output_amps : func {
        if(me.switch.getValue()){
        var x = 1.0 - me.charge_percent;
        var tmp = -(3.0 * x - 1.0);
        var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
        var output =me.ideal_amps * factor;
        return output;
        }else return 0;
    }
};

# var alternator = Alternator.new(num,switch,rpm_source,rpm_threshold,volts,amps);
var Alternator = {
    new : func (num,switch,src,thr,vlt,amp){
        m = { parents : [Alternator] };
        m.switch =  props.globals.getNode(switch,1);
        m.switch.setBoolValue(0);
        m.meter =  props.globals.getNode("systems/electrical/gen-load["~num~"]",1);
        m.meter.setDoubleValue(0);
        m.gen_output =  props.globals.getNode("engines/engine["~num~"]/amp-v",1);
        m.gen_output.setDoubleValue(0);
        m.meter.setDoubleValue(0);
        m.rpm_source =  props.globals.getNode(src,1);
        m.rpm_threshold = thr;
        m.ideal_volts = vlt;
        m.ideal_amps = amp;
        return m;
    },

    apply_load : func(load) {
        var cur_volt=me.gen_output.getValue();
        var cur_amp=me.meter.getValue();
        if(cur_volt >1){
            var factor=1/cur_volt;
            gout = (load * factor);
            if(gout>1)gout=1;
        }else{
            gout=0;
        }
        me.meter.setValue(gout);
    },

    get_output_volts : func {
        var out = 0;
        if(me.switch.getBoolValue()){
            var factor = me.rpm_source.getValue() / me.rpm_threshold or 0;
            if ( factor > 1.0 )factor = 1.0;
            var out = (me.ideal_volts * factor);
        }
        me.gen_output.setValue(out);
        return out;
    },

    get_output_amps : func {
        var ampout =0;
        if(me.switch.getBoolValue()){
            var factor = me.rpm_source.getValue() / me.rpm_threshold or 0;
            if ( factor > 1.0 ) {
                factor = 1.0;
            }
            ampout = me.ideal_amps * factor;
        }
        return ampout;
    }
};

var battery = Battery.new("/controls/electric/battery-switch",24,30,34,1.0,7.0);
var alternator1 = Alternator.new(0,"controls/electric/engine[0]/generator","/engines/engine[0]/rpm",20.0,28.0,60.0);
var alternator2 = Alternator.new(1,"controls/electric/engine[1]/generator","/engines/engine[1]/rpm",20.0,28.0,60.0);

#####################################
setlistener("/sim/signals/fdm-initialized", func {
    init_switches();
    settimer(update_electrical,5);
    print("Electrical System ... ok");
});

var init_switches = func{
    var AVswitch=props.globals.initNode("controls/electric/avionics-switch",0,"BOOL");
    setprop("controls/lighting/instruments-norm",0.8);
    setprop("controls/lighting/engines-norm",0.8);
    props.globals.initNode("controls/electric/ammeter-switch",0,"BOOL");
    props.globals.getNode("systems/electrical/serviceable",0,"BOOL");
    props.globals.getNode("controls/electric/external-power",0,"BOOL");
    setprop("controls/lighting/instrument-lights-norm",0.8);
    setprop("controls/lighting/efis-norm",0.8);
    setprop("controls/lighting/panel-norm",0.8);

    append(lights_input,props.globals.initNode("controls/lighting/landing-light[0]",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/landing-light[0]",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/landing-light[1]",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/landing-light[1]",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/landing-light[2]",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/landing-light[2]",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/nav-lights",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/nav-lights",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/cabin-lights",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/cabin-lights",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/map-lights",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/map-lights",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/wing-lights",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/wing-lights",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/recog-lights",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/recog-lights",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/logo-lights",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/logo-lights",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/taxi-lights",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/taxi-lights",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/beacon-state/state",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/beacon",0,"DOUBLE"));
    append(lights_load,1);
    append(lights_input,props.globals.initNode("controls/lighting/strobe-state/state",0,"BOOL"));
    append(lights_output,props.globals.initNode("systems/electrical/outputs/strobe",0,"DOUBLE"));
    append(lights_load,1);

    append(rbus_input,props.globals.initNode("controls/electric/wiper-switch",0,"BOOL"));
    append(rbus_output,props.globals.initNode("systems/electrical/outputs/wiper",0,"DOUBLE"));
    append(rbus_load,1);
    append(rbus_input,props.globals.initNode("controls/engines/engine[0]/fuel-pump",0,"BOOL"));
    append(rbus_output,props.globals.initNode("systems/electrical/outputs/fuel-pump[0]",0,"DOUBLE"));
    append(rbus_load,1);
    append(rbus_input,props.globals.initNode("controls/engines/engine[1]/fuel-pump",0,"BOOL"));
    append(rbus_output,props.globals.initNode("systems/electrical/outputs/fuel-pump[1]",0,"DOUBLE"));
    append(rbus_load,1);
    append(rbus_input,props.globals.initNode("controls/engines/engine[0]/starter",0,"BOOL"));
    append(rbus_output,props.globals.initNode("systems/electrical/outputs/starter",0,"DOUBLE"));
    append(rbus_load,1);
    append(rbus_input,props.globals.initNode("controls/engines/engine[1]/starter",0,"BOOL"));
    append(rbus_output,props.globals.initNode("systems/electrical/outputs/starter[1]",0,"DOUBLE"));
    append(rbus_load,1);
    append(rbus_input,AVswitch);
    append(rbus_output,props.globals.initNode("systems/electrical/outputs/KNS80",0,"DOUBLE"));
    append(rbus_load,1);
    append(rbus_input,AVswitch);
    append(rbus_output,props.globals.initNode("systems/electrical/outputs/efis",0,"DOUBLE"));
    append(rbus_load,1);


    append(lbus_input,AVswitch);
    append(lbus_output,props.globals.initNode("systems/electrical/outputs/adf",0,"DOUBLE"));
    append(lbus_load,1);
    append(lbus_input,AVswitch);
    append(lbus_output,props.globals.initNode("systems/electrical/outputs/dme",0,"DOUBLE"));
    append(lbus_load,1);
    append(lbus_input,AVswitch);
    append(lbus_output,props.globals.initNode("systems/electrical/outputs/gps",0,"DOUBLE"));
    append(lbus_load,1);
    append(lbus_input,AVswitch);
    append(lbus_output,props.globals.initNode("systems/electrical/outputs/DG",0,"DOUBLE"));
    append(lbus_load,1);
    append(lbus_input,AVswitch);
    append(lbus_output,props.globals.initNode("systems/electrical/outputs/transponder",0,"DOUBLE"));
    append(lbus_load,1);
    append(lbus_input,AVswitch);
    append(lbus_output,props.globals.initNode("systems/electrical/outputs/mk-viii",0,"DOUBLE"));
    append(lbus_load,1);
    append(lbus_input,AVswitch);
    append(lbus_output,props.globals.initNode("systems/electrical/outputs/turn-coordinator",0,"DOUBLE"));
    append(lbus_load,1);
    append(lbus_input,AVswitch);
    append(lbus_output,props.globals.initNode("systems/electrical/outputs/comm",0,"DOUBLE"));
    append(lbus_load,1);
    append(lbus_input,AVswitch);
    append(lbus_output,props.globals.initNode("systems/electrical/outputs/comm[1]",0,"DOUBLE"));
    append(lbus_load,1);
    append(lbus_input,AVswitch);
    append(lbus_output,props.globals.initNode("systems/electrical/outputs/nav",0,"DOUBLE"));
    append(lbus_load,1);
    append(lbus_input,AVswitch);
    append(lbus_output,props.globals.initNode("systems/electrical/outputs/nav[1]",0,"DOUBLE"));
    append(lbus_load,1);
}


update_virtual_bus = func( dt ) {
    var PWR = getprop("systems/electrical/serviceable");
    var xtie=0;
    load = 0.0;
    power_source = nil;
    if(count==0){
        var battery_volts = battery.get_output_volts();
        lbus_volts = battery_volts;
        power_source = "battery";
        var alternator1_volts = alternator1.get_output_volts();
        if (alternator1_volts > lbus_volts) {
            lbus_volts = alternator1_volts;
            power_source = "alternator1";
        }
        lbus_volts *=PWR;
        Lbus.setValue(lbus_volts);
        load += lh_bus(lbus_volts);
            alternator1.apply_load(load);
    }else{
        var battery_volts = battery.get_output_volts();
        rbus_volts = battery_volts;
        power_source = "battery";
        var alternator2_volts = alternator2.get_output_volts();
        if (alternator2_volts > rbus_volts) {
            rbus_volts = alternator2_volts;
            power_source = "alternator2";
        }
        rbus_volts *=PWR;
        Rbus.setValue(rbus_volts);
        load += rh_bus(rbus_volts);
        alternator2.apply_load(load);
    }
    count=1-count;
    if(rbus_volts > 5 and  lbus_volts>5) xtie=1;
    XTie.setValue(xtie);
    if(rbus_volts > 5 or  lbus_volts>5) load += lighting(24);

    ammeter = 0.0;

return load;
}

rh_bus = func(bv) {
    var bus_volts = bv;
    var load = 0.0;
    var srvc = 0.0;

    for(var i=0; i<size(rbus_input); i+=1) {
        var srvc = rbus_input[i].getValue();
        load += rbus_load[i] * srvc;
        rbus_output[i].setValue(bus_volts * srvc);
    }
    return load;
}

lh_bus = func(bv) {
    var load = 0.0;
    var srvc = 0.0;

    for(var i=0; i<size(lbus_input); i+=1) {
        var srvc = lbus_input[i].getValue();
        load += lbus_load[i] * srvc;
        lbus_output[i].setValue(bv * srvc);
    }

    setprop("systems/electrical/outputs/flaps",bv);
    return load;
}

lighting = func(bv) {
    var load = 0.0;
    var srvc = 0.0;
    var ac=bv*4.29;

    for(var i=0; i<size(lights_input); i+=1) {
        var srvc = lights_input[i].getValue();
        load += lights_load[i] * srvc;
        lights_output[i].setValue(bv * srvc);
    }

return load;

}

update_electrical = func {
    var scnd = getprop("sim/time/delta-sec");
    update_virtual_bus( scnd );
settimer(update_electrical, 0);
}

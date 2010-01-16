/* [{
Copyright 2007, 2008, 2009 Nicolas Carranza <nicarran at gmail.com>

This file is part of jpen.

jpen is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

jpen is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with jpen.  If not, see <http://www.gnu.org/licenses/>.
}] */
package jpen;

import java.awt.geom.Point2D;
import java.awt.Point;
import java.util.ArrayList;
import java.util.Collection;
import java.util.EnumMap;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.Map;
import jpen.owner.PenOwner;
import jpen.internal.filter.RelativeLocationFilter;

final class PenScheduler{
	static final Logger L=Logger.getLogger(PenScheduler.class.getName());
	//static { L.setLevel(Level.ALL); }

	private final Pen pen;
	private PenEvent lastScheduledEvent;
	public final PenState lastScheduledState=new PenState();
	private final SystemMouseFilter systemMouseFilter;
	private final List<PLevel> scheduledLevels=new ArrayList<PLevel>();

	PenScheduler(Pen pen){
		this.pen=pen;
		lastScheduledEvent=pen.getLastDispatchedEvent();
		this.systemMouseFilter=new SystemMouseFilter(pen.penManager);
	}

	/**
	The SystemMouseFilter is used to fitler system mouse movement to avoid conflict with movements coming from other devices.
	*/
	private static class SystemMouseFilter {
		public static int THRESHOLD_PERIOD=200;
		private final PenManager penManager;
		private PenDevice lastDevice; // last device NOT filtered
		private PenEvent lastEvent; // last event scheduled
		boolean filteredFirstInSecuence;
		private long time;
		private long firstInSecuenceTime;
		
		SystemMouseFilter(PenManager penManager){
			this.penManager=penManager;
		}
		/**
		@return {@code true} if the device is the system mouse and other device has already scheduled level events
		*/
		boolean filterOut(PenDevice device) {
			if(penManager.isSystemMouseDevice(device)) {
				time=System.currentTimeMillis();
				if(lastDevice!=null &&
					 lastDevice!=device &&
					 lastEvent!=null &&
					 time-lastEvent.time<=THRESHOLD_PERIOD
					)
					return true;
				if(!filteredFirstInSecuence) {
					L.fine("filtered first in sequence to prioritize digitized input in race");
					filteredFirstInSecuence=true;
					firstInSecuenceTime=System.currentTimeMillis();
					return true;
				}
				if(time-firstInSecuenceTime<=THRESHOLD_PERIOD){
					L.fine("filtering after the first for a period to allow digitized input to come and win in race");
					return true;
				}
				L.fine("non digitized input going as event");
			} else
				filteredFirstInSecuence=false;
			lastDevice=device;
			return false;
		}

		void setLastEvent(PenEvent event) {
			this.lastEvent=event;
		}

		PenEvent getLastEvent() {
			return lastEvent;
		}
	}

	private boolean firstScheduleAfterPause;

	void setPaused(boolean paused){
		if(paused)
			scheduleButtonReleasedEvents();
		else{
			firstScheduleAfterPause=true;
			relativeLocationFilter.reset();
		}
	}

	private final Point clipLocationOnScreen=new Point();
	private final Point2D.Float scheduledLocation=new Point2D.Float();
	private final RelativeLocationFilter relativeLocationFilter=new RelativeLocationFilter();

	synchronized boolean scheduleLevelEvent(PenDevice device, long deviceTime, Collection<PLevel> levels, boolean levelsOnScreen) {

		if(device.getProvider().getUseRelativeLocationFilter()){
			if(relativeLocationFilter.filter(lastScheduledState, device, levels, levelsOnScreen))
				switch(relativeLocationFilter.getState()){
				case RELATIVE:
					device.penManagerSetUseFractionalMovements(false);
					break;
				case ABSOLUTE:
					device.penManagerSetUseFractionalMovements(true);
					break;
				default:
				}
		}

		if(getEmulationDevice()!=device // the emulation device must not cause filtering of system mouse events
			&& systemMouseFilter.filterOut(device)
		) 
			return false;

		if(device.getKindTypeNumber()!=PKind.Type.IGNORE.ordinal() &&
			 device.getKindTypeNumber() !=lastScheduledState.getKind().typeNumber){
			PKind newKind=PKind.valueOf(device.getKindTypeNumber());
			if(L.isLoggable(Level.FINE)){
				L.fine("changing kind to:"+newKind);
				L.fine("scheduledLevels: "+scheduledLevels);
				L.fine("device: "+device);
			}
			lastScheduledState.setKind(newKind);
			schedule(new PKindEvent(device, deviceTime, newKind));
		}

		scheduledLevels.clear();
		float scheduledPressure=-1, lastScheduledPressure=-1;
		boolean scheduledMovement=false;
		scheduledLocation.x=lastScheduledState.levels.getValue(PLevel.Type.X);
		scheduledLocation.y=lastScheduledState.levels.getValue(PLevel.Type.Y);
		PenOwner penOwner=pen.penManager==null? null:pen.penManager.penOwner; // pen.penManager can be null when testing
		if(penOwner!=null && levelsOnScreen)
			penOwner.getPenClip().evalLocationOnScreen(clipLocationOnScreen);
		for(PLevel level:levels) {
			if(device!=getEmulationDevice() && pen.levelEmulator!=null &&
				 pen.levelEmulator.onActivePolicy(lastScheduledState.getKind().getType().ordinal(),
						 level.typeNumber))
				continue;
			if(level.isMovement()){
				if(levelsOnScreen){
					switch(level.getType() ){
					case X:
						level.value=level.value-clipLocationOnScreen.x;
						scheduledLocation.x=level.value;
						break;
					case Y:
						level.value=level.value-clipLocationOnScreen.y;
						scheduledLocation.y=level.value;
						break;
					default:
						throw new AssertionError();
					}
				}
				if(!firstScheduleAfterPause && level.value==lastScheduledState.getLevelValue(level.typeNumber))
					continue;
				scheduledMovement=true;
			}else{
				if(!firstScheduleAfterPause && level.value==lastScheduledState.getLevelValue(level.typeNumber))
					continue;
				switch(level.getType()){
				case PRESSURE:
					scheduledPressure=level.value;
					lastScheduledPressure=lastScheduledState.levels.getValue(PLevel.Type.PRESSURE);
					break;
				default:
				}
			}
			scheduledLevels.add(level);
		}
		if(scheduledLevels.isEmpty())
			return false;
		firstScheduleAfterPause=false;

		if(scheduledMovement){
			if(penOwner!=null && !penOwner.getPenClip().contains(scheduledLocation)
				 && !penOwner.isDraggingOut())
				return false;
		}

		lastScheduledState.levels.setValues(scheduledLevels);
		PLevelEvent levelEvent=new PLevelEvent(device, deviceTime,
				scheduledLevels.toArray(new PLevel[scheduledLevels.size()]));
		systemMouseFilter.setLastEvent(levelEvent);
		scheduleOnPressureButtonEvent(lastScheduledPressure, scheduledPressure);
		schedule(levelEvent);
		return true;
	}

	private void scheduleOnPressureButtonEvent(float lastScheduledPressure, float scheduledPressure){
		if(lastScheduledPressure==0 && scheduledPressure>0)
			scheduleEmulatedButtonEvent(new PButton(PButton.Type.ON_PRESSURE.ordinal(), true));
		else if(lastScheduledPressure>0 && scheduledPressure==0)
			scheduleEmulatedButtonEvent(new PButton(PButton.Type.ON_PRESSURE.ordinal(), false));
	}

	synchronized void scheduleButtonReleasedEvents(){
		for(int i=PButton.Type.VALUES.size(); --i>=0;)
			scheduleEmulatedButtonEvent(new PButton(i, false));
		for(Integer extButtonTypeNumber: lastScheduledState.extButtonTypeNumberToValue.keySet())
			scheduleEmulatedButtonEvent(new PButton(extButtonTypeNumber, false));
	}

	private void scheduleEmulatedButtonEvent(PButton button){
		scheduleButtonEvent(getEmulationDevice(), System.currentTimeMillis(), button);
	}

	private PenDevice getEmulationDevice(){
		return pen.penManager.emulationDevice;
	}

	synchronized void scheduleButtonEvent(PenDevice device, long deviceTime, PButton button) {
		if(lastScheduledState.setButtonValue(button.typeNumber, button.value)){
			if(L.isLoggable(Level.FINE))
				L.fine("scheduling button event: "+button);
			PButtonEvent buttonEvent=new PButtonEvent(device, deviceTime, button);
			schedule(buttonEvent);
			if(pen.levelEmulator!=null)
				pen.levelEmulator.scheduleEmulatedEvent(buttonEvent);
		}
	}

	synchronized void scheduleScrollEvent(PenDevice device, long deviceTime, PScroll scroll) {
		schedule(new PScrollEvent(device, deviceTime, scroll));
	}

	private void schedule(PenEvent ev) {
		ev.time=System.currentTimeMillis();
		lastScheduledEvent.next=ev;
		lastScheduledEvent=ev;
		pen.processNewEvents();
	}
}
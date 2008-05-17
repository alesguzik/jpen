/* [{
* (C) Copyright 2007 Nicolas Carranza and individual contributors.
* See the jpen-copyright.txt file in the jpen distribution for a full
* listing of individual contributors.
*
* This file is part of jpen.
*
* jpen is free software: you can redistribute it and/or modify
* it under the terms of the GNU Lesser General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* jpen is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public License
* along with jpen.  If not, see <http://www.gnu.org/licenses/>.
* }] */
package jpen;

import java.util.List;

public abstract class TypedClass<T extends Enum<T>>
	implements java.io.Serializable {
	public static final long serialVersionUID=1l;
	public final int typeNumber;

	TypedClass(int typeNumber) {
		if(typeNumber<0)
			throw new IllegalArgumentException();
		this.typeNumber=typeNumber;
	}

	abstract List<T> getTypes();

	/**
	WARNING: This method returns {@code null} when the {@link #typeNumber} does not match any of the enum type ordinals. Only 3rd party providers can cause {@code null} return values (JPen (internal) providers do not).  When you get a {@code null} you can use the {@link #typeNumber} directly as instructed by the 3rd party provider. 
	
	@return The enum type matching the {@link #typeNumber}, or {@code null} if there is no match.
	*/
	public final T getType() {
		return getType(typeNumber);
	}

	private final T getType(int typeNumber){
		if(typeNumber<0 || typeNumber>=getTypes().size())
			return null;
		return getTypes().get(typeNumber);
	}

	@Override
	public String toString() {
		return "(type="+getType()+")";
	}
}

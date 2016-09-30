/*
 * Copyright © 2001-2008 Wouter van Oortmerssen
 * Copyright © 2008-2016 Jonathan Dowland <jon@dow.land>
 *
 * Distributed under the terms of the GNU GPL Version 2
 * See file LICENSE.txt
 */

package org.redmars.wadc;
import java.util.*;

public class Side {
  int idx;
  Sector s = null;
  Line l;
  Side(Line x, Vector addto) {
    l = x;
    idx = addto.size();
    addto.addElement(this);
  }
  Side cloneadd(Line l, Vector sides) {
    Side s = new Side(l,sides);
    s.s = this.s;
    return s;
  }
}


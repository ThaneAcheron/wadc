/*
potential todos:
- "autorim" feature: draws an inner sector to the next sector
- zdoom thing id
- check curve xoff accuracy?
- render thing orientation?
- make a way to have the xo() macro be independant of undefx?
- add undefy? -> not practical, because it has different effects on mid/bot/top
- fix can't draw when no lines drawn?
- curb lazyness? in some code (with loops) this is really the bottleneck
  -> happens mainly in recursive functions, which can easily be given _
  what would be cool is a strictness analysis for all parameters that
  are used twice, for all callers wether the argument is "functional".
  This could automatically speed up all code, but is not trivial.
- arches give unexpected bugs with lower subdiv?
- fix alignment in arches?
- randow walk line
- textures:
  * add custom textures directly from jpg? (easy)
  * custom texture wad automatic merging? (medium)
  * iwad+custom texture browsing (medium)
- support map02 etc in one source
- mirroring (difficult: needs to be at both line/vertex level, reverse rotation doesn't work)
- opengl preview (+ editing?)
- generic lighting (place a lightsource... draw sectors automatically)

*/

import java.awt.*;
import java.util.*;
import java.io.InputStream;
import java.io.IOException;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.Path;
import java.nio.file.LinkOption;

public class WadParse {
  int linenum = 1;
  int pos = 0;
  char token = 0;
  String buf;
  String err = null;
  String sinfo = "";
  int iinfo = 0;
  int curtag = 10;
  int editinsertpos = 0;
  int editchanged = 0;
  Hashtable funs = new Hashtable();
  Hashtable globs = new Hashtable();
  Hashtable tags = new Hashtable();
  MainFrame mf;
  Hashtable includes = new Hashtable();

  TreeMap<String,Texture> textures = new TreeMap<String,Texture>();
  Texture current_texture = null;

  // new patch definitions
  ArrayList<String> patches = new ArrayList<String>();

  WadRun wr = new WadRun(this);

  void error(String s) { throw new Error(s); }
  void warn(String s) { mf.msg("parser ["+linenum+"]: "+s); }

  public WadParse(String s, MainFrame m) {
    mf = m;
    buf = s+((char)0);
    wr.addbuiltins();
    try {
      lex();
      while(token!=0) {
        if(token=='#') {
          attachinclude();
        } else {
          Fun f = parsefun();
          if(funs.put(f.name,f)!=null) error("function "+f.name+" defined twice");
        };
      };
    } catch(Error e) {
      err = "parser ["+linenum+"]: "+e.getMessage();
      mf.msg(err);
    };
  }

  void lex() {
    for(;;) switch(token = buf.charAt(pos++)) {
      case '\n': linenum++; case '\t': case ' ': continue;
      case 0: pos--; return;
      case '\"': {
        String s = "";
        for(;;) {
          token = buf.charAt(pos++);
          if(token=='\"' || token==0) break;
          s+=token;
        };
        if(token==0) { pos--; return; };
        sinfo = s;
        return;
      }
      case '-':
        if(buf.charAt(pos)=='-') {
          do {
            token = buf.charAt(++pos);
          } while(token!='\n' && token!=0);

          continue;
        };
        parseint("-");
        return;
      case '/':
        if(buf.charAt(pos)=='*') {
          pos++;
          while(buf.charAt(pos)!='*' || buf.charAt(pos+1)!='/') {
            pos++;
            if(pos+1==buf.length()) error("multiline comment not closed");
          };
          pos += 2;
          continue;
        };
      default:
        if(Character.isLetter(token) || token=='_') {
          String s = ""+token;
          while(Character.isLetterOrDigit(token = buf.charAt(pos)) || token=='_') { pos++; s+=token; };
          sinfo = s;
          token = 'a';
          return;
        };
        if(Character.isDigit(token)) {
          parseint(""+token);
          return;
        };
        return;
    }
  }

  /*
   * resolve an include directive to a file inside the Jar.
   */
  String loadIncludeFromJar(String name) {
    String ret = "";
    byte[] foo = new byte[4096];
    InputStream input = getClass().getResourceAsStream("/include/"+name);

    if(null == input)
      return ret;

    try {
      // holy smokes this sucks.
      int len;
      do {
        len = input.read(foo);
        if(len > 0) ret += new String(Arrays.copyOfRange(foo, 0, len - 1), "UTF-8");
      } while(0 < len);

    } catch(IOException e) {
        mf.msg("couldn't load " + name);
    }
    return ret;
  }

  String loadinclude(String name) {
      ArrayList<String> l = new ArrayList<String>();
      Path p = Paths.get(mf.basename).getParent();
      p = Paths.get(p.toString(), name);

      if(! Files.isRegularFile(p)) {
          mf.msg("trying to resolve " + name + " via jar...");
          return loadIncludeFromJar(name);
      } else {
          mf.msg("resolving " + name + " as file");
      }

      try {
        Files.lines(p).forEach(line -> l.add(line));

      } catch(IOException i) {
        mf.msg("couldn't load file "+name);
      };

      String ret = String.join("\n", l);
      System.out.println("debug: " + name + "\n" + ret);
      return ret;
  }

  void attachinclude() {
    lex();
    if(token!='\"') error("filename expected");
    if(includes.get(sinfo)==null) {
      includes.put(sinfo,sinfo);
      buf = buf.substring(0,buf.length()-1) + loadinclude(sinfo) +'\0';
    };
    lex();
  }

  void parseint(String s) {
    while(Character.isDigit(token = buf.charAt(pos))) { pos++; s+=token; };
    iinfo = Integer.parseInt(s);
    token = '1';
  }

  void expect(char c) {
    if(token!=c) error(c+" expected");
    lex();
  }

  String expectid() {
    if(token!='a') error("identifier expected");
    String s = sinfo;
    lex();
    return s;
  };

  Fun parsefun() {
    Fun f = new Fun(expectid());
    if(token=='(') {
      lex();
      while(token!=')') {
        f.args.addElement(expectid());
        if(token!=')') expect(',');
      };
      lex();
    };
    expect('{');
    f.body = parseexp();
    if(f.name.compareTo("main")==0 && token=='}') editinsertpos = pos-1;
    expect('}');
    return f;
  }

  Exp parseexp() {
    Exp e = parsechoice();
    if(token=='?') {
      lex();
      If i = new If(e);
      i.then = parsechoice();
      expect(':');
      i.els = parsechoice();
      return i;
    };
    return e;
  };

  Exp parsechoice() {
    Exp e = parseseq();
    if(token=='|') {
      Choice c = new Choice();
      c.add(e);
      while(token=='|') {
        lex();
        c.add(parseseq());
      };
      return c;
    };
    return e;
  };

  Exp parseseq() {
    Exp e = parsefact();
    if(token!='?' && token!=':' && token!='}' && token !=')' && token!=',' && token!='|') {
      return new Seq(e,parseseq());
    };
    return e;
  }

  Exp parsefact() {
    switch(token) {
      case '!':
      case '^': {
        boolean set = token=='!';
        lex();
        SetGet sg = new SetGet();
        sg.name = expectid();
        sg.set = set;
        return sg;
      }
      case '$': {
        lex();
        String name = expectid();
        Int i = (Int)tags.get(name);
        if(i==null) {
          i = new Int(curtag++);
          tags.put(name,i);
        };
        return i;
      }
      case '{': {
        lex();
        Exp e = parseexp();
        expect('}');
        return e;
      }
      case '1': {
        Int i = new Int(iinfo);
        lex();
        return i;
      }
      case '\"': {
        Str s = new Str(sinfo);
        lex();
        return s;
      }
      case 'a': {
        Id i = new Id(sinfo);
        lex();
        if(token=='(') {
          lex();
          while(token!=')') {
            if(i.v==null) i.v = new Vector();
            i.v.addElement(parseexp());
            if(token!=')') expect(',');
          };
          lex();
        };
        return i;
      }

      default: error("expression expected");
    };
    return null;
  }

  void run() { wr.run(); };

  void setTexture(String s, int w, int h) {
      Texture t = textures.get(s);
      if(null == t) {
          t = new Texture(s,w,h);
          textures.put(s,t);
      }
      current_texture = t;
  }

  void addPatch(String n, int x, int y) {
      if(null != current_texture) {
          current_texture.patches.add(new Patch(n, x, y));
      }
  }

  void newPatch(String n) {
      patches.add(n);
  }

}

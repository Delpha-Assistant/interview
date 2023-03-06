/**
 * This is a Tool class used to normalize name from a flow or any other place
 * using the InvocableMethod annotation.
 * 
 * It provides a single entry-point allowing caller to configure the normalization.
 */
global with sharing class NameNormalizer {

  /**
   * This is the parameter type for the normalization process.
   * Strategies will always be processed in the same order:
   * unicode - title - space - case
   */
  @JsonAccess(serializable='always' deserializable='always')
  global class Input {
    /**
     * List of names to normalize
     */
    @InvocableVariable(label='Records to normalize' description='List of records to normalize.' required=true)
    global List<SObject> records;

    /**
     * List of fields to normalize for each record (must be text fields)
     */
    @InvocableVariable(label='Fields to normalize' description='List of fields to normalize for each object.' required=true)
    global List<String> fields;

    /**
     * Defines the strategy to be used for case normalization. Possible values are:
     *  - identity (default): case is not changed => "Stéphanie DE MONACO"
     *  - uppercase: everything turned to uppercase => "STÉPHANIE DE MONACO"
     *  - lowercase: everything turned to lowercase => "stéphanie de monaco"
     *  - capitalized: first letter of each word is uppercase, others are lowercase => "Stéphanie De Monaco"
     *  - name: Same as capitalized but tries to be clever with particles: "Stéphanie de Monaco"
     */
    @InvocableVariable(label='Case strategy' description='Strategy to use to normalize case (identity, uppercase, lowercase, capitalized, name).')
    global String strategyCase;

    /**
     * Defines the strategy to be used for unicode normalization. Possible values are:
     *  - identity (default): nothing is changed => "Stéphanie DE MONACO 🐬"
     *  - ascii: keep only ascii chars (code 1-127) => "Stphanie DE MONACO "
     *  - ascii-extended: keep only ascii chars (code 1-255) => "Stéphanie DE MONACO "
     *  - ascii-convert: tries to convert unicode to ascii relative if possible => "Stephanie DE MONACO "
     */
    @InvocableVariable(label='Unicode strategy' description='Strategy to use to normalize unicode chars (identity, ascii, ascii-extended, ascii-convert).')
    global String strategyUnicode;

    /**
     * Defines the strategy to be used for spacing normalization. Possible values are:
     *  - identity (default): nothing is changed => " Stéphanie   de  Monaco    "
     *  - trim: removes leading and traling spaces => "Stéphanie   de  Monaco"
     *  - normalize: consecutives spaces are merged into one => " Stéphanie de Monaco "
     *  - clean: trim + normalize => "Stéphanie de Monaco"
     */
    @InvocableVariable(label='Spacing strategy' description='Strategy to use to normalize spaces (identity, trim, normalize, clean).')
    global String strategySpacing;

    /**
     * Defines the strategy to be used for title normalization. Possible values are:
     *  - identity (default): nothing is changed => "Stéphanie Jr  de Monaco PHD "
     *  - remove: remove title from the name => "Stéphanie  de Monaco "
     */
    @InvocableVariable(label='Title strategy' description='Strategy to use to normalize titles (identity, remove).')
    global String strategyTitle;
  }

  /**
   * Flow entry point of the normalization process.
   * Receives a list of inputs and processes each of them separately.
   */
  @InvocableMethod(label='Normalize Names' description='Normalize names according to given settings.' category='Tools')
  global static void normalizeNames(List<Input> inputs) {
    for(Input input : inputs) {
      normalizeInput(input);
    }
  }

  /**
   * Normalize a single input by dispatching processing to the correct strategies.
   */
  private static void normalizeInput(Input input) {
    if(input == null || input.records == null) {
      return;
    }

    for(SObject record : input.records) {
      for(String field : input.fields) {
        String value = (String)record.get(field);
        value = normalizeUnicode(value, input.strategyUnicode);
        value = normalizeTitle(value, input.strategyTitle);
        value = normalizeSpacing(value, input.strategySpacing);
        value = normalizeCase(value, input.strategyCase);
        record.put(field, value);
      }
    }
  }

  /**
   * Normalize unicode chars according to strategy
   */
  private static String normalizeUnicode(String name, String strategy) {
    if(name == null) {
      return null;
    }

    switch on strategy {
      when 'ascii' {
        return normalizeUnicodeLimit(name, 0, 128);
      }
      when 'ascii-extended' {
        return normalizeUnicodeLimit(name, 0, 256);
      }
      when 'ascii-convert' {
        //First convert what can be converted, then limit
        name = normalizeUnicodeConvert(name);
        return normalizeUnicodeLimit(name, 0, 128);
      }
      when else {
        //Identity or unkown strategy ==> do nothing
        return name;
      }
    }
  }

  /**
   * Remove from name all chars whose unicode value is out of bound [lower;upper[
   */
  private static String normalizeUnicodeLimit(String name, Integer lowerBound, Integer upperBound) {
    List<Integer> result = new List<Integer>();
    for(Integer index = 0; index < name.length(); ++index) {
      Integer ch = name.charAt(index);

      if(ch >= lowerBound && ch <upperBound) {
        result.add(ch);
      }
    }

    return String.fromCharArray(result);
  }

  /**
   * List of known titles that we want to remove from names.
   */
  private static Set<String> TITLES = new Set<String>{'SENIOR', 'DOCTOR', 'JUNIOR', 'JR', 'MS', 'MR', 'SR', 'PH','PHD', 'CHEF', 'BS', 'BSC', 'ACIR', 'PCR', 'CSMR', 'CSSR', 'CIR', 'SALESFORCE', 'SFDC', 'MANAGER', 
  'MSC', 'MARKETING', 'SVP', 'VSN', 'JOB', 'CMA', 'CSM', 'IT', 'MSEC', 'MSCBA', 'MSCS', 'PMP', 'LEADER', 'SRK', 'MBA', 'RESEARCH', 'CSA', 'FSC', 'CPP', 'PCC', 'PM',
  'CM', 'PRO', 'AWS', 'CSA P', 'CSA A', 'CSO A', 'MCP', 'MCT'};

  /**
   * Normalize titles according to strategy
   */
  private static String normalizeTitle(String name, String strategy) {
    if(name == null) {
      return null;
    }

    if(strategy != 'remove') {
      //remove is the only strategy that should do something. If anything else then don't do anything.
      return name;
    }

    //Each word in the name is handled separately. If it is a title => discard the word.
    //Dirty hack: split will eat trailing spaces, add random char to make sure it doesn't happen
    List<String> parts = (name + ' #').split(' ');
    List<String> result = new List<String>();
    for(String part: parts) {
      if(!TITLES.contains(part.toUpperCase())) {
        result.add(part);
      }
    }

    //Dirsty hack step 2 => remove our char
    result.remove(result.size() - 1);

    //Build full name back
    return String.join(result, ' ');
  }

  /**
   * Normalize case according to strategy
   */
  private static String normalizeCase(String name, String strategy) {
    if(name == null) {
      return null;
    }

    switch on strategy {
      when 'uppercase' {
        return name.toUpperCase();
      }	
      when 'lowercase' {
        return name.toLowerCase();
      }
      when 'capitalize' {
        return capitalizeName(name, false); //false => do not handle particle
      }
      when 'name' {
        return capitalizeName(name, true);  //true => do handle particle
      }
      when else {
        //Identity or unknown strategy ==> Don't do anything
        return name;
      }
    }
  }

  /**
   * Normalize spacing according to strategy
   */
  private static String normalizeSpacing(String name, String strategy) {
    if(name == null) {
      return null;
    }

    //Trim
    if(strategy == 'trim' || strategy == 'clean') {
      name = name.trim();
    }

    //Normalize
    if(strategy == 'normalize' || strategy == 'clean') {
      //Split on spaces, then do not insert back empty parts
      List<String> parts = name.split(' ');
      List<String> result = new List<String>();

      //If string starts with spaces, they will be removed, we do not want that (this had to be done by trim nor normalize)
      if(name.startsWith(' ')) {
        result.add('');
      }

      for(String part : parts) {
        if(part != '') {
          result.add(part);
        }
      }

      //If string ends with spaces, they will be removed, we do not want that (this had to be done by trim nor normalize)
      if(name.endsWith(' ')) {
        result.add('');
      }

      name = String.join(result, ' ');
    }

    //Name should now be clean
    return name;
  }

  /**
   * List of known name particles.
   * FREE_PARTICLES should be a full word and will not be capitalized
   * ATTACHED_PARTICLE are attached at the beginning of a name and need transformation (match => how to render)
   */
  private static Set<String> FREE_PARTICLES = new Set<String>{'de', 'del', 'des', 'und', 'van', 'von', 'zu'};
  private static Map<String, String> ATTACHED_PARTICLES = new Map<String, String>{
    'd\''=> 'd\'',
    'o\'' => 'O\'',
    'mac' => 'Mac',
    'mc' => 'Mc'
  };

  private static String capitalizeName(String name, Boolean handleParticle) {
    //Each word in the name is handled separately
    List<String> parts = name.split(' ');
    List<String> result = new List<String>();
    for(String part : parts) {
      //Most of the string will be lowercase, lowercase everything here to help locate particles
      part = part.toLowerCase();

      //If requested, extract particle
      String particle = '';
      if(handleParticle) {
        particle = extractParticle(part);
        part = part.substring(particle.length());
      }

      //First letter, and each letter after a - should be uppercased
      List<String> subparts = part.split('-');
      List<String> subpartsCapitalized = new List<String>();
      for(String subpart : subparts) {
        //First letter should be capitalized
        String firstLetter = '';
        if(subpart.length() > 0) {
          firstLetter = subpart.substring(0, 1).toUpperCase();
          subpartsCapitalized.add(firstLetter + subpart.substring(1));
        }
      }
      
      //Rebuild full part
      result.add(particle + String.join(subpartsCapitalized, '-'));
    } 

    //Assemble result with spaces
    return String.join(result, ' ');
  }

  /**
   * Extract particle from a name part
   */
  private static String extractParticle(String name) {
    //Try with FREE_PARTICLES first
    if(FREE_PARTICLES.contains(name)) {
      return name;
    }

    //Not a free particle, try ATTACHED ones
    for(String key: ATTACHED_PARTICLES.keySet()) {
      if(name.startsWith(key)) {
        return ATTACHED_PARTICLES.get(key);
      }
    }

    //Not found, no particle
    return '';
  }



  /**
   * This is the official way of handling accents on Salesforce :(
   * This map contains all know mapping from accent to non accent versions of each char.
   */
  private static String normalizeUnicodeConvert(String name)
  {
      for (String letter : PATTERNS.keySet())
          name = name.replaceAll(patterns.get(letter), letter);
      return name;
  }
  private static Map<String, String> PATTERNS = new Map<String, String>
  {
      'A' => '[\u0041\u24B6\uFF21\u00C0\u00C1\u00C2\u1EA6\u1EA4\u1EAA\u1EA8\u00C3\u0100\u0102\u1EB0\u1EAE\u1EB4\u1EB2\u0226\u01E0\u00C4\u01DE\u1EA2\u00C5\u01FA\u01CD\u0200\u0202\u1EA0\u1EAC\u1EB6\u1E00\u0104\u023A\u2C6F]',
      'AA' => '[\uA732]',
      'AE' => '[\u00C6\u01FC\u01E2]',
      'AO' => '[\uA734]',
      'AU' => '[\uA736]',
      'AV' => '[\uA738\uA73A]',
      'AY' => '[\uA73C]',
      'B' => '[\u0042\u24B7\uFF22\u1E02\u1E04\u1E06\u0243\u0182\u0181]',
      'C' => '[\u0043\u24B8\uFF23\u0106\u0108\u010A\u010C\u00C7\u1E08\u0187\u023B\uA73E]',
      'D' => '[\u0044\u24B9\uFF24\u1E0A\u010E\u1E0C\u1E10\u1E12\u1E0E\u0110\u018B\u018A\u0189\uA779]',
      'DZ' => '[\u01F1\u01C4]',
      'Dz' => '[\u01F2\u01C5]',
      'E' => '[\u0045\u24BA\uFF25\u00C8\u00C9\u00CA\u1EC0\u1EBE\u1EC4\u1EC2\u1EBC\u0112\u1E14\u1E16\u0114\u0116\u00CB\u1EBA\u011A\u0204\u0206\u1EB8\u1EC6\u0228\u1E1C\u0118\u1E18\u1E1A\u0190\u018E]',
      'F' => '[\u0046\u24BB\uFF26\u1E1E\u0191\uA77B]',
      'G' => '[\u0047\u24BC\uFF27\u01F4\u011C\u1E20\u011E\u0120\u01E6\u0122\u01E4\u0193\uA7A0\uA77D\uA77E]',
      'H' => '[\u0048\u24BD\uFF28\u0124\u1E22\u1E26\u021E\u1E24\u1E28\u1E2A\u0126\u2C67\u2C75\uA78D]',
      'I' => '[\u0049\u24BE\uFF29\u00CC\u00CD\u00CE\u0128\u012A\u012C\u0130\u00CF\u1E2E\u1EC8\u01CF\u0208\u020A\u1ECA\u012E\u1E2C\u0197]',
      'J' => '[\u004A\u24BF\uFF2A\u0134\u0248]',
      'K' => '[\u004B\u24C0\uFF2B\u1E30\u01E8\u1E32\u0136\u1E34\u0198\u2C69\uA740\uA742\uA744\uA7A2]',
      'L' => '[\u004C\u24C1\uFF2C\u013F\u0139\u013D\u1E36\u1E38\u013B\u1E3C\u1E3A\u0141\u023D\u2C62\u2C60\uA748\uA746\uA780]',
      'LJ' => '[\u01C7]',
      'Lj' => '[\u01C8]',
      'M' => '[\u004D\u24C2\uFF2D\u1E3E\u1E40\u1E42\u2C6E\u019C]',
      'N' => '[\u004E\u24C3\uFF2E\u01F8\u0143\u00D1\u1E44\u0147\u1E46\u0145\u1E4A\u1E48\u0220\u019D\uA790\uA7A4]',
      'NJ' => '[\u01CA]',
      'Nj' => '[\u01CB]',
      'O' => '[\u004F\u24C4\uFF2F\u00D2\u00D3\u00D4\u1ED2\u1ED0\u1ED6\u1ED4\u00D5\u1E4C\u022C\u1E4E\u014C\u1E50\u1E52\u014E\u022E\u0230\u00D6\u022A\u1ECE\u0150\u01D1\u020C\u020E\u01A0\u1EDC\u1EDA\u1EE0\u1EDE\u1EE2\u1ECC\u1ED8\u01EA\u01EC\u00D8\u01FE\u0186\u019F\uA74A\uA74C]',
      'OI' => '[\u01A2]',
      'OO' => '[\uA74E]',
      'OU' => '[\u0222]',
      'P' => '[\u0050\u24C5\uFF30\u1E54\u1E56\u01A4\u2C63\uA750\uA752\uA754]',
      'Q' => '[\u0051\u24C6\uFF31\uA756\uA758\u024A]',
      'R' => '[\u0052\u24C7\uFF32\u0154\u1E58\u0158\u0210\u0212\u1E5A\u1E5C\u0156\u1E5E\u024C\u2C64\uA75A\uA7A6\uA782]',
      'S' => '[\u0053\u24C8\uFF33\u1E9E\u015A\u1E64\u015C\u1E60\u0160\u1E66\u1E62\u1E68\u0218\u015E\u2C7E\uA7A8\uA784]',
      'T' => '[\u0054\u24C9\uFF34\u1E6A\u0164\u1E6C\u021A\u0162\u1E70\u1E6E\u0166\u01AC\u01AE\u023E\uA786]',
      'TZ' => '[\uA728]',
      'U' => '[\u0055\u24CA\uFF35\u00D9\u00DA\u00DB\u0168\u1E78\u016A\u1E7A\u016C\u00DC\u01DB\u01D7\u01D5\u01D9\u1EE6\u016E\u0170\u01D3\u0214\u0216\u01AF\u1EEA\u1EE8\u1EEE\u1EEC\u1EF0\u1EE4\u1E72\u0172\u1E76\u1E74\u0244]',
      'V' => '[\u0056\u24CB\uFF36\u1E7C\u1E7E\u01B2\uA75E\u0245]',
      'VY' => '[\uA760]',
      'W' => '[\u0057\u24CC\uFF37\u1E80\u1E82\u0174\u1E86\u1E84\u1E88\u2C72]',
      'X' => '[\u0058\u24CD\uFF38\u1E8A\u1E8C]',
      'Y' => '[\u0059\u24CE\uFF39\u1EF2\u00DD\u0176\u1EF8\u0232\u1E8E\u0178\u1EF6\u1EF4\u01B3\u024E\u1EFE]',
      'Z' => '[\u005A\u24CF\uFF3A\u0179\u1E90\u017B\u017D\u1E92\u1E94\u01B5\u0224\u2C7F\u2C6B\uA762]',
      'a' => '[\u0061\u24D0\uFF41\u1E9A\u00E0\u00E1\u00E2\u1EA7\u1EA5\u1EAB\u1EA9\u00E3\u0101\u0103\u1EB1\u1EAF\u1EB5\u1EB3\u0227\u01E1\u00E4\u01DF\u1EA3\u00E5\u01FB\u01CE\u0201\u0203\u1EA1\u1EAD\u1EB7\u1E01\u0105\u2C65\u0250]',
      'aa' => '[\uA733]',
      'ae' => '[\u00E6\u01FD\u01E3]',
      'ao' => '[\uA735]',
      'au' => '[\uA737]',
      'av' => '[\uA739\uA73B]',
      'ay' => '[\uA73D]',
      'b' => '[\u0062\u24D1\uFF42\u1E03\u1E05\u1E07\u0180\u0183\u0253]',
      'c' => '[\u0063\u24D2\uFF43\u0107\u0109\u010B\u010D\u00E7\u1E09\u0188\u023C\uA73F\u2184]',
      'd' => '[\u0064\u24D3\uFF44\u1E0B\u010F\u1E0D\u1E11\u1E13\u1E0F\u0111\u018C\u0256\u0257\uA77A]',
      'dz' => '[\u01F3\u01C6]',
      'e' => '[\u0065\u24D4\uFF45\u00E8\u00E9\u00EA\u1EC1\u1EBF\u1EC5\u1EC3\u1EBD\u0113\u1E15\u1E17\u0115\u0117\u00EB\u1EBB\u011B\u0205\u0207\u1EB9\u1EC7\u0229\u1E1D\u0119\u1E19\u1E1B\u0247\u025B\u01DD]',
      'f' => '[\u0066\u24D5\uFF46\u1E1F\u0192\uA77C]',
      'g' => '[\u0067\u24D6\uFF47\u01F5\u011D\u1E21\u011F\u0121\u01E7\u0123\u01E5\u0260\uA7A1\u1D79\uA77F]',
      'h' => '[\u0068\u24D7\uFF48\u0125\u1E23\u1E27\u021F\u1E25\u1E29\u1E2B\u1E96\u0127\u2C68\u2C76\u0265]',
      'hv' => '[\u0195]',
      'i' => '[\u0069\u24D8\uFF49\u00EC\u00ED\u00EE\u0129\u012B\u012D\u00EF\u1E2F\u1EC9\u01D0\u0209\u020B\u1ECB\u012F\u1E2D\u0268\u0131]',
      'j' => '[\u006A\u24D9\uFF4A\u0135\u01F0\u0249]',
      'k' => '[\u006B\u24DA\uFF4B\u1E31\u01E9\u1E33\u0137\u1E35\u0199\u2C6A\uA741\uA743\uA745\uA7A3]',
      'l' => '[\u006C\u24DB\uFF4C\u0140\u013A\u013E\u1E37\u1E39\u013C\u1E3D\u1E3B\u017F\u0142\u019A\u026B\u2C61\uA749\uA781\uA747]',
      'lj' => '[\u01C9]',
      'm' => '[\u006D\u24DC\uFF4D\u1E3F\u1E41\u1E43\u0271\u026F]',
      'n' => '[\u006E\u24DD\uFF4E\u01F9\u0144\u00F1\u1E45\u0148\u1E47\u0146\u1E4B\u1E49\u019E\u0272\u0149\uA791\uA7A5]',
      'nj' => '[\u01CC]',
      'o' => '[\u006F\u24DE\uFF4F\u00F2\u00F3\u00F4\u1ED3\u1ED1\u1ED7\u1ED5\u00F5\u1E4D\u022D\u1E4F\u014D\u1E51\u1E53\u014F\u022F\u0231\u00F6\u022B\u1ECF\u0151\u01D2\u020D\u020F\u01A1\u1EDD\u1EDB\u1EE1\u1EDF\u1EE3\u1ECD\u1ED9\u01EB\u01ED\u00F8\u01FF\u0254\uA74B\uA74D\u0275]',
      'oi' => '[\u01A3]',
      'ou' => '[\u0223]',
      'oo' => '[\uA74F]',
      'p' => '[\u0070\u24DF\uFF50\u1E55\u1E57\u01A5\u1D7D\uA751\uA753\uA755]',
      'q' => '[\u0071\u24E0\uFF51\u024B\uA757\uA759]',
      'r' => '[\u0072\u24E1\uFF52\u0155\u1E59\u0159\u0211\u0213\u1E5B\u1E5D\u0157\u1E5F\u024D\u027D\uA75B\uA7A7\uA783]',
      's' => '[\u0073\u24E2\uFF53\u00DF\u015B\u1E65\u015D\u1E61\u0161\u1E67\u1E63\u1E69\u0219\u015F\u023F\uA7A9\uA785\u1E9B]',
      't' => '[\u0074\u24E3\uFF54\u1E6B\u1E97\u0165\u1E6D\u021B\u0163\u1E71\u1E6F\u0167\u01AD\u0288\u2C66\uA787]',
      'tz' => '[\uA729]',
      'u' => '[\u0075\u24E4\uFF55\u00F9\u00FA\u00FB\u0169\u1E79\u016B\u1E7B\u016D\u00FC\u01DC\u01D8\u01D6\u01DA\u1EE7\u016F\u0171\u01D4\u0215\u0217\u01B0\u1EEB\u1EE9\u1EEF\u1EED\u1EF1\u1EE5\u1E73\u0173\u1E77\u1E75\u0289]',
      'v' => '[\u0076\u24E5\uFF56\u1E7D\u1E7F\u028B\uA75F\u028C]',
      'vy' => '[\uA761]',
      'w' => '[\u0077\u24E6\uFF57\u1E81\u1E83\u0175\u1E87\u1E85\u1E98\u1E89\u2C73]',
      'x' => '[\u0078\u24E7\uFF58\u1E8B\u1E8D]',
      'y' => '[\u0079\u24E8\uFF59\u1EF3\u00FD\u0177\u1EF9\u0233\u1E8F\u00FF\u1EF7\u1E99\u1EF5\u01B4\u024F\u1EFF]',
      'z' => '[\u007A\u24E9\uFF5A\u017A\u1E91\u017C\u017E\u1E93\u1E95\u01B6\u0225\u0240\u2C6C\uA763]'
  };
}
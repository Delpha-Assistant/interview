@IsTest
public class NameNormalizerTest {
  @isTest
  public static void test_identity_by_default() {
    List<Contact> contacts = generateContacts();
    List<Contact> originals = generateContacts();

    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = contacts;
    input.fields = new List<String>{'FirstName', 'LastName'};

    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    System.assertEquals(originals, contacts, 'Names should remain the same');
  }

  @isTest
  public static void test_identity_explicit() {
    List<Contact> contacts = generateContacts();
    List<Contact> originals = generateContacts();

    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = contacts;
    input.fields = new List<String>{'FirstName', 'LastName'};
    input.strategyCase = 'identity';
    input.strategySpacing = 'identity';
    input.strategyTitle = 'identity';
    input.strategyUnicode = 'identity';

    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    System.assertEquals(originals, contacts, 'Names should remain the same');
  }

  @isTest
  public static void test_case_upper() {
    List<Contact> contacts = generateContacts();

    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = contacts;
    input.fields = new List<String>{'FirstName', 'LastName'};
    input.strategyCase = 'uppercase';

    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    System.assertEquals('ALBERT', contacts[0].FirstName, 'Names should be uppercase');
    System.assertEquals('STÉPHANIE', contacts[1].FirstName, 'Names should be uppercase');
    System.assertEquals('JEANNE  ', contacts[2].FirstName, 'Names should be uppercase');
    System.assertEquals('DE LA FONTAINE', contacts[3].LastName, 'Names should be uppercase');
    System.assertEquals('DES       CARS', contacts[4].LastName, 'Names should be uppercase');
    System.assertEquals('MACLEOD', contacts[5].LastName, 'Names should be uppercase');
    System.assertEquals('JEAN-ROGER-ÉRIC', contacts[13].FirstName, 'Names should be uppercase');
  }

  @isTest
  public static void test_case_lower() {
    List<Contact> contacts = generateContacts();

    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = contacts;
    input.fields = new List<String>{'FirstName', 'LastName'};
    input.strategyCase = 'lowercase';

    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    System.assertEquals('albert', contacts[0].FirstName, 'Names should be lowercase');
    System.assertEquals('stéphanie', contacts[1].FirstName, 'Names should be lowercase');
    System.assertEquals('jeanne  ', contacts[2].FirstName, 'Names should be lowercase');
    System.assertEquals('de la fontaine', contacts[3].LastName, 'Names should be lowercase');
    System.assertEquals('des       cars', contacts[4].LastName, 'Names should be lowercase');
    System.assertEquals('macleod', contacts[5].LastName, 'Names should be lowercase');
  }

  @isTest
  public static void test_case_capitalize() {
    List<Contact> contacts = generateContacts();

    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = contacts;
    input.fields = new List<String>{'FirstName', 'LastName'};
    input.strategyCase = 'capitalize';

    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    System.assertEquals('Johannes Adam Ferdinand Alois Josef', contacts[8].FirstName, 'Names should be capitalized');
    System.assertEquals('D\'aviano Pius Von Und Zu Liechtenstein', contacts[8].LastName, 'Names should be capitalized');
    System.assertEquals('De    Monaco 🐬', contacts[1].LastName, 'Names should be capitalized');
    System.assertEquals('D\'arc', contacts[2].LastName, 'Names should be capitalized');
    System.assertEquals('De La Fontaine', contacts[3].LastName, 'Names should be capitalized');
    System.assertEquals('Des       Cars', contacts[4].LastName, 'Names should be capitalized');
    System.assertEquals('Macleod', contacts[5].LastName, 'Names should be capitalized');
    System.assertEquals('O\'neal', contacts[6].LastName, 'Names should be capitalized');
    System.assertEquals('Von Bismark', contacts[7].LastName, 'Names should be capitalized');
    System.assertEquals('Graf Zu Pappenheim', contacts[9].LastName, 'Names should be capitalized');
    System.assertEquals('Del Potro', contacts[10].LastName, 'Names should be capitalized');
    System.assertEquals('Van Aert', contacts[11].LastName, 'Names should be capitalized');
    System.assertEquals('Jean-Roger-Éric', contacts[13].FirstName, 'Names should be capitalized');
    System.assertEquals('Mcarthur', contacts[14].LastName, 'Names should be capitalized');
  }

  @isTest
  public static void test_case_name() {
    List<Contact> contacts = generateContacts();

    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = contacts;
    input.fields = new List<String>{'FirstName', 'LastName'};input.strategyCase = 'name';

    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    System.assertEquals('Johannes Adam Ferdinand Alois Josef', contacts[8].FirstName, 'Names should be capitalized with particle');
    System.assertEquals('d\'Aviano Pius von und zu Liechtenstein', contacts[8].LastName, 'Names should be capitalized with particle');
    System.assertEquals('de    Monaco 🐬', contacts[1].LastName, 'Names should be capitalized with particle');
    System.assertEquals('d\'Arc', contacts[2].LastName, 'Names should be capitalizedwith particle');
    System.assertEquals('de La Fontaine', contacts[3].LastName, 'Names should be capitalized with particle');
    System.assertEquals('des       Cars', contacts[4].LastName, 'Names should be capitalized with particle');
    System.assertEquals('MacLeod', contacts[5].LastName, 'Names should be capitalized with particle');
    System.assertEquals('O\'Neal', contacts[6].LastName, 'Names should be capitalized with particle');
    System.assertEquals('von Bismark', contacts[7].LastName, 'Names should be capitalized with particle');
    System.assertEquals('Graf zu Pappenheim', contacts[9].LastName, 'Names should be capitalized with particle');
    System.assertEquals('del Potro', contacts[10].LastName, 'Names should be capitalized with particle');
    System.assertEquals('van Aert', contacts[11].LastName, 'Names should be capitalized with particle');
    System.assertEquals('Jean-Roger-Éric', contacts[13].FirstName, 'Names should be capitalized with particle');
    System.assertEquals('McArthur', contacts[14].LastName, 'Names should be capitalized with particle');
  }

  @isTest
  public static void test_unicode_ascii() {
    List<Contact> contacts = generateContacts();

    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = contacts;
    input.fields = new List<String>{'FirstName', 'LastName'};
    input.strategyUnicode = 'ascii';

    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    System.assertEquals('Stphanie', contacts[1].FirstName, 'Non-ascii chars should have been removed');
    System.assertEquals('de    Monaco ', contacts[1].LastName, 'Non-ascii chars should have been removed');
    System.assertEquals('  Juan  Martn  ', contacts[10].FirstName, 'Non-ascii chars should have been removed');
    System.assertEquals('Pawe', contacts[12].FirstName, 'Non-ascii chars should have been removed');
    System.assertEquals('jean-ROGER-ric', contacts[13].FirstName, 'Hyphen should have been kept');
  }

  @isTest
  public static void test_unicode_ascii_extended() {
    List<Contact> contacts = generateContacts();

    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = contacts;
    input.fields = new List<String>{'FirstName', 'LastName'};
    input.strategyUnicode = 'ascii-extended';

    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    System.assertEquals('Stéphanie', contacts[1].FirstName, 'Non-ascii-extended chars should have been removed');
    System.assertEquals('de    Monaco ', contacts[1].LastName, 'Non-ascii-extended chars should have been removed');
    System.assertEquals('  Juan  Martín  ', contacts[10].FirstName, 'Non-ascii-extended chars should have been removed');
    System.assertEquals('Pawe', contacts[12].FirstName, 'Non-ascii-extended chars should have been removed');
    System.assertEquals('jean-ROGER-éric', contacts[13].FirstName, 'Hyphen should have been kept');
  }

  @isTest
  public static void test_unicode_ascii_convert() {
    List<Contact> contacts = generateContacts();

    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = contacts;
    input.fields = new List<String>{'FirstName', 'LastName'};
    input.strategyUnicode = 'ascii-convert';

    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    System.assertEquals('Stephanie', contacts[1].FirstName, 'Non-ascii-extended chars should have been converted');
    System.assertEquals('de    Monaco ', contacts[1].LastName, 'Non-ascii-extended chars should have been converted');
    System.assertEquals('  Juan  Martin  ', contacts[10].FirstName, 'Non-ascii-extended chars should have been converted');
    System.assertEquals('Pawel', contacts[12].FirstName, 'Non-ascii-extended chars should have been converted');
  }

  @isTest
  public static void test_spacing_trim() {
    List<Contact> contacts = generateContacts();

    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = contacts;
    input.fields = new List<String>{'FirstName', 'LastName'};
    input.strategySpacing = 'trim';

    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    System.assertEquals('de    Monaco 🐬', contacts[1].LastName, 'Leading and trailing spaces should have been trimmed');
    System.assertEquals('Juan  Martín', contacts[10].FirstName, 'Leading and trailing spaces should have been trimmed');
    System.assertEquals('Wout', contacts[11].FirstName, 'Leading and trailing spaces should have been trimmed');
    System.assertEquals('jean-ROGER-éric', contacts[13].FirstName, 'Hyphen should have been kept');
  }

  @isTest
  public static void test_spacing_normalize() {
    List<Contact> contacts = generateContacts();

    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = contacts;
    input.fields = new List<String>{'FirstName', 'LastName'};
    input.strategySpacing = 'normalize';

    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    System.assertEquals('de Monaco 🐬', contacts[1].LastName, 'Multi spaces should have been normalized');
    System.assertEquals(' Juan Martín ', contacts[10].FirstName, 'Multi spaces should have been normalized');
    System.assertEquals(' Wout ', contacts[11].FirstName, 'Multi spaces should have been normalized');
  }

  @isTest
  public static void test_spacing_clean() {
    List<Contact> contacts = generateContacts();

    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = contacts;
    input.fields = new List<String>{'FirstName', 'LastName'};
    input.strategySpacing = 'clean';

    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    System.assertEquals('de Monaco 🐬', contacts[1].LastName, 'Name should have been trimmed and cleaned');
    System.assertEquals('Juan Martín', contacts[10].FirstName, 'Name should have been trimmed and cleaned');
    System.assertEquals('Wout', contacts[11].FirstName, 'Name should have been trimmed and cleaned');
    System.assertEquals('jean-ROGER-éric', contacts[13].FirstName, 'Hyphen should have been kept');
  }

  @isTest
  public static void test_title_remove() {
    List<Contact> contacts = generateContacts();

    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = contacts;
    input.fields = new List<String>{'FirstName', 'LastName'};
    input.strategyTitle = 'remove';

    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    System.assertEquals('Gottfried Heinrich', contacts[9].FirstName, 'Titles should have been removed');
    System.assertEquals('Lamba Vannier', contacts[13].LastName, 'Title should not be removed from inside name');
  }

  @isTest
  public static void test_ultimate() {
    List<Contact> contacts = generateContacts();

    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = contacts;
    input.fields = new List<String>{'FirstName', 'LastName'};
    input.strategyCase = 'name';
    input.strategyUnicode = 'ascii-convert';
    input.strategySpacing = 'clean';
    input.strategyTitle = 'remove';

    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    System.assertEquals('de Monaco', contacts[1].LastName, 'String should be perfect');
    System.assertEquals('de Lewandowski', contacts[12].LastName, 'String should be perfect');
  }
  
  ///////////////////////// EDGE CASES ///////////////////////////////////////////
  @isTest
  public static void test_null_input() {
    //Null input should crash, just noop
    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{null});
  }

  @isTest
  public static void test_multiple_input() {
    List<Contact> contacts1 = generateContacts();
    List<Contact> contacts2 = generateContacts();

    NameNormalizer.Input input1 = new NameNormalizer.Input();
    input1.records = contacts1;
    input1.fields = new List<String>{'FirstName', 'LastName'};
    input1.strategyCase = 'uppercase';

    NameNormalizer.Input input2 = new NameNormalizer.Input();
    input2.records = contacts2;
    input2.fields = new List<String>{'FirstName', 'LastName'};
    input2.strategyCase = 'lowercase';
  
    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input1, input2});

    System.assertEquals('ALBERT', contacts1[0].FirstName, 'First list should be uppercase');
    System.assertEquals('albert', contacts2[0].FirstName, 'Second list should be lowercase');
  }

  @isTest
  public static void test_null_list() {
    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = null;
    input.strategyCase = 'name';
    input.strategyUnicode = 'ascii-convert';
    input.strategySpacing = 'clean';
    input.strategyTitle = 'remove';
 
    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    //Normalizer should noop without crashing
  }

  @isTest
  public static void test_null_entry() {
    List<Contact> contacts = generateContacts();
    contacts[0].FirstName = null;

    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = contacts;
    input.fields = new List<String>{'FirstName', 'LastName'};
    input.strategyCase = 'uppercase';

    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    System.assertEquals(null, contacts[0].FirstName, 'NULL entry should remain NULL');
    System.assertEquals('EINSTEIN', contacts[0].LastName, 'Other entries should be handled');
    System.assertEquals('GUY', contacts[4].FirstName, 'Other entries should be handled');
  }

  @isTest
  public static void test_unknown_strategy() {
    List<Contact> contacts = generateContacts();
    List<Contact> originals = generateContacts();

    NameNormalizer.Input input = new NameNormalizer.Input();
    input.records = contacts;
    input.fields = new List<String>{'FirstName', 'LastName'};
    input.strategyCase = 'unknown';
    input.strategySpacing = 'unkown';
    input.strategyTitle = 'unknown';
    input.strategyUnicode = 'unknown';

    NameNormalizer.normalizeNames(new List<NameNormalizer.Input>{input});

    System.assertEquals(originals, contacts, 'Unknown strategy is same as identity');
  }

  private static List<Contact> generateContacts() {
    return new List<Contact> {
      new Contact(FirstName='Albert', LastName='Einstein'), //0
      new Contact(FirstName='Stéphanie', LastName='de    Monaco 🐬'), //1
      new Contact(FirstName='Jeanne  ', LastName='d\'arc'), //2
      new Contact(FirstName='JEAN', LastName='DE la FoNtAiNe'), //3
      new Contact(FirstName='guy', LastName='des       cars'), //4
      new Contact(FirstName='dunCAN', LastName='Macleod'), //5
      new Contact(FirstName='Shaquille', LastName='o\'neal'), //6
      new Contact(FirstName='OttO', LastName='VON BISMARK'), //7
      new Contact(FirstName='johannes adam ferdinand alois josef', LastName='d\'aviano pius von und zu liechtenstein'), //8
      new Contact(FirstName='Dr Gottfried Jr Heinrich', LastName='Graf zu Pappenheim'), //9
      new Contact(FirstName='  Juan  Martín  ', LastName='del Potro'), //10
      new Contact(FirstName='  Wout  ', LastName='van aert'), //11
      new Contact(FirstName='Paweł', LastName=' Dr de   Lewandowski    MBA  '), //12
      new Contact(FirstName='jean-ROGER-éric', LastName='Lamba Vannier'), //13
      new Contact(FirstName='Eward', LastName='mcarthur') //14
    };
  }
}
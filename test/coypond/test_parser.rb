require 'helper'
require 'coypond/parser'
require 'ripper'

class TestParser < Test::Unit::TestCase
  should  "correctly extract const_ref" do
    result = Coypond::Parser.new.extract_ref(*[:const_ref, [:@const, "Baz", [1, 22]]])
    assert_equal ["Baz", [1, 22]], result
  end
  
  should  "correctly extract var_ref" do
    result = Coypond::Parser.new.extract_ref(*[:var_ref, [:@const, "Baz", [1, 22]]])
    assert_equal ["Baz", [1, 22]], result
  end
  
  should  "correctly extract const_path_ref" do
    result = Coypond::Parser.new.extract_ref(*[:const_path_ref,
                                               [:var_ref, [:@const, "Bar", [1, 22]]],
                                               [:@const, "Baz", [1, 24]]])
    assert_equal ["Bar::Baz", [1, 24]], result
  end
  
  should "capture instances of `class` in classes instance variable" do
    parse_tree = [:program,
                  [:stmts_add,
                    [:stmts_add,
                      [:stmts_new],
                      [:class, [:const_ref, [:@const, "Foo", [1, 6]]], nil,
                                [:bodystmt,
                                  [:stmts_add,
                                    [:stmts_new],
                                    [:void_stmt]], nil, nil, nil]]],
                    [:class, [:const_ref, [:@const, "Baz", [1, 22]]], nil,
                                [:bodystmt,
                                  [:stmts_add,
                                    [:stmts_new],
                                    [:void_stmt]], nil, nil, nil]]]]
    parser = Coypond::Parser.new.parse(parse_tree)

    assert_equal ["Foo", "Baz"], parser.classes.keys
  end

  should "use fully qualified class name in classes instance variable" do
    parse_tree = [:class,
                   [:const_path_ref,
                     [:var_ref,
                       [:@const, "Bar", [1, 6]]],
                     [:@const, "Foo", [1, 11]]],
                   nil,
                   [:bodystmt, [:stmts_add, [:stmts_new], [:void_stmt]], nil, nil, nil]]
    parser = Coypond::Parser.new.parse(parse_tree)
    
    assert_equal ["Bar::Foo"], parser.classes.keys
  end
  
  should "use multi-level fully qualified class name in classes instance variable" do
    parse_tree = [:class,
                   [:const_path_ref,
                     [:const_path_ref,
                       [:var_ref,
                         [:@const, "Bar", [1, 6]]],
                       [:@const, "Baz", [1, 11]]],
                     [:@const, "Foo", [1, 16]]],
                     nil,
                     [:bodystmt, [:stmts_add, [:stmts_new], [:void_stmt]], nil, nil, nil]]
    parser = Coypond::Parser.new.parse(parse_tree)
    
    assert_equal ["Bar::Baz::Foo"], parser.classes.keys
  end

  should "use fully qualified class name with module in classes instance variable" do
    parse_tree = [:module, [:const_ref, [:@const, "Bar", [1, 7]]],
                           [:bodystmt, [:stmts_add, [:stmts_add, [:stmts_new], [:void_stmt]],
                                       [:class, [:const_ref, [:@const, "Foo", [1, 17]]], nil,
                                                [:bodystmt,
                                                  [:stmts_add,
                                                    [:stmts_new],
                                                    [:void_stmt]], nil, nil, nil]]], nil, nil, nil]]
    parser = Coypond::Parser.new.parse(parse_tree)
    
    assert_equal ["Bar::Foo"], parser.classes.keys
  end
  
  should "capture instances of `module` in modules instance variable" do
    parse_tree = [:module, [:const_ref, [:@const, "Bar", [1, 7]]],
                           [:bodystmt, [:stmts_add, [:stmts_new], [:void_stmt]], nil, nil, nil]]
    parser = Coypond::Parser.new.parse(parse_tree)
    
    assert_equal ["Bar"], parser.modules.keys
  end
  
  should "capture instances of `def` in methods instance variable" do
    parse_tree = [:def, [:@ident, "foo", [1, 4]],
                        [:params, nil, nil, nil, nil, nil],
                        [:bodystmt, [:stmts_add, [:stmts_new], [:void_stmt]], nil, nil, nil]]
    parser = Coypond::Parser.new.parse(parse_tree)
    
    assert_equal ["foo"], parser.methods.keys
  end
  
end

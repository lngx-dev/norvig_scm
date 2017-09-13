# coding: utf-8

# *** トークン生成 ***
def tokenize(s)
  s.gsub(/[()]/, ' \0 ').split
end
# tokens = tokenize "(define plus1 (lambda (n) (+ n 1)))"
# => ["(", "define", "plus1", "(", "lambda", "(", "n", ")", "(", "+", "n", "1", ")", ")", ")"]
# パーサはまず読込んだプログラムの文字列をその構文要素であるトークン(token)に分割します。
# カッコの前後に空白を挿入してsplitによる分割がうまくいくように前処理している点がポイントです。
# String#gsubに正規表現を渡すことで両カッコの前処理を一度にしています。


# *** トークン列の解析 ***
def read_from(tokens)
  raise SytaxError, 'unexpected EOF while reading' if tokens.length == 0
  case token = tokens.shift
  when '('
    l = []
    until tokens[0] == ')' # peep tokens[0] to confirm if it's ')'
      l.push read_from(tokens)
    end
    tokens.shift           # remove taokens[0] == ')'
    l
  when ')'
    raise SyntaxError, 'unexpected )'
  else
    atom(token)
  end
end
# parsed_tokens = read_from(tokens)
# => ["define", "plus1", ["lambda", ["n"], ["+", "n", "1"]]]
# 基本的にread_fromはトークンのリストを受け取り、先頭から１つづつ再帰的にトークンを解析します。
# 具体的にはその先頭が開きカッコか否かを判定します。
# そうでない場合それは数かシンボルなのでelse節のatomでトークンをrubyの対応する表現に変換して返します。
# 開きカッコである場合はリストを用意し、閉じカッコが現れるまでのトークンをここに入れますが、
# ここでread_fromを再帰的に呼び出すことによって、後続のトークンが適切に処理されるようにします。
# つまり後続のトークンの先頭が開きカッコである場合は、上記同様リストが用意されてそこに後続トークンを入れる処理がされ、
# そうでない場合はatomでreadの表現に変換されます。
# このコードは再帰を使ったエレガントで強力なアルゴリズムです。以上の処理によりschemeのリストはrubyのリストに変換されます。
# RubyではSchemeのリスト、数、シンボルをそれぞれRubyのArray、数、シンボルで表現します。


# *** トークン変換 ***
module Kernel
  def Symbol(obj); obj.intern end
end
def atom(token, type=[:Integer, :Float, :Symbol])
  send(type.shift, token)
rescue ArgumentError
  retry
end
puts "#{atom("1")}   #{atom("1").class}"   # => 1   Integer
puts "#{atom("1.1")} #{atom("1.1").class}" # => 1.1 Float
puts "#{atom("one")} #{atom("one").class}" # => one Symbol
# 次にトークンをインタプリタの表現に変換する関数atomを見ます。
# 最初にトークンのintへの変換を試み、次にfloatへの変換を試み、最後にSymbolへの変換を試みています。
# ここでは、rescue節でretryを使うことでコードを簡潔にしました。
# ただSymbolという関数メソッドが未定義なのでこれを用意しています。


# *** パーサ・インタフェース ***
def read(s)
  read_from tokenize(s)
end
alias :parse :read
# tokenize, read_from を統合したパーサのインタフェースはこのようになります。


# *** 評価(eval) ***
def evaluate(x, env=$global_env)
  case x
  when Symbol       # 1. ref variable
    env.find(x)[x]
  when Array        # 2. in list
    case x.first
    when :quote     #     2-1. (quoto exp)
      _, exp = x
      exp
    when :if        #     2-2. (if test conseq alt)
      _, test, conseq, alt = x
      evaluate((evaluate(test, env) ? conseq : alt), env)
    when :set!      #     2-3. (set! var exp)
      _, var, exp = x
      env.find(var)[var] = evaluate(exp, env)
    when :define    #     2-4. (defaine var exp)
      _, var, exp = x
      env[var] = evaluate(exp, env)
      nil
    when :lambda    #     2-5. (lambda (var*) exp)
      _, vars, exp = x
      lambda { |*args| evaluate(exp, Env.new(vars, args, env)) }
    when :begin     #     2-6. (begin exp*)
      x[1..-1].inject(nil) { |val, exp| val = evaluate(exp, env) }
    else            #     2-7. (proc exp*)
      proc, *exps = x.inject([]) { |mem, exp| mem << evaluate(exp, env) }
      proc[*exps]
    end
  else              # 3. const literal
    x
  end
end
# evalの中身はif文による上記の9ケースの場合分け処理になっています。
# evalに与えられた内部表現(パースされたプログラム文字列)がリストである場合、
# 特殊形式の何れかの処理でその構成要素が再帰的にeval処理されます。
# そしてeval対象がシンボルであれば、環境を定義したenvオブジェクトを参照してその実体を返します。
# シンボルでもリストでもない場合は、数字などの定数としてそのまま返します。
# eval対象が特殊形式でないリストである場合(8. else節)、これを手続きとしてその内容を実行します。
# なおevalの第２引数は環境オブジェクトenvを取ります。
# これは内部表現を評価する際にそれが定義された環境を区別する必要があるためです。
# これによってローカル変数がグローバルに評価されるようなことがなくなります。
# 初期値はグローバル環境にセットされます。
# proc[exps]はproc.call(exps)と等価でprocの実行です。


# *** 環境クラス定義 ***
class Env < Hash
  def initialize(parms=[], args=[], outer=nil)
    h = Hash[parms.zip(args)]
    self.merge!(h)
    @outer = outer
  end

  def find(key)
    self.has_key?(key) ? self : @outer.find(key)
  end
end
# 環境クラスENVはハッシュのサブクラスで、オブジェクト生成時に与えられた変数とその実体をハッシュとして保持します。
# Array#zipメソッドで変数のリストと実体のリストからハッシュを生成しマージします。
#   [:a, :b].zip([1,2])       => [[:a, 1], [:b, 2]]
#   Hash[[:a, :b].zip([1,2])] => {:a=>1, :b=>2}
# そのオブジェクトが内部環境を構築するつまり外部環境を持っている場合、
# それを第３引数として渡してオブジェクトを生成します。
# これはeval関数内のlambdaにおける処理で使われています。
# findメソッドは与えられた変数に対応する実体を返します。
# その環境で変数が定義されていない場合、その１つ外側の環境で対応する実体を探します。
# 外部環境outerはオブジェクトの外からアクセスする必要はないので、インスタンス変数@outerに保持します。


# *** グローバル環境オブジェクト ***
$global_env = Env.new.merge!(
  :+       => ->x, y {x + y},
  :-       => ->x, y {x - y},
  :*       => ->x, y {x * y},
  :/       => ->x, y {x / y},
  :not     => ->x    {!x},
  :>       => ->x, y {x > y},
  :<       => ->x, y {x < y},
  :>=      => ->x, y {x >= y},
  :<=      => ->x, y {x <= y},
  :'='     => ->x, y {x == y},
  :equal?  => ->x, y {x.equal?(y)},
  :eq?     => ->x, y {x.eql? y},
  :length  => ->x    {x.length},
  :cons    => ->x, y {[x,y]},
  :car     => ->x    {x[0]},
  :cdr     => ->x    {x[1..-1]},
  :append  => ->x, y {x+y},
  :list    => ->*x   {[*x]},
  :list?   => ->x    {x.instance_of?(Array)},
  :null?   => ->x    {x.empty?},
  :symbol? => ->x    {x.instance_of?(Symbol)}
)
# 環境クラスが定義できたのでこれを使ってグローバル環境オブジェクトを生成します。
# グローバル環境にはSchemeの組込み手続きを含めます。
# この外部環境オブジェクトはグローバル変数global_envで参照できるようにセットされ、
# その結果どこからでもアクセスできるようになります。
# すべてlambdaで生成しています。Ruby1.9で導入された->表記がこういうところでは便利です。


# *** 実行 ***
tokens = tokenize "(define plus1 (lambda (n) (+ n 1)))"
print "tokens: "
p tokens

parsed_tokens = read_from(tokens)
print "parsed_tokens: "
p parsed_tokens

p parse("(+ 3 (* 4 5))")
p parse("(define plus1 (lambda (n) (+ n 1)))")
p parse("(define area (lambda (r) (* 3.141592653 (* r r))))")

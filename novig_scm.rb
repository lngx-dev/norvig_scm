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

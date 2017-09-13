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
    #atom(token) # next step
    token
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


# *** 実行 ***
tokens = tokenize "(define plus1 (lambda (n) (+ n 1)))"
print "tokens: "
p tokens

parsed_tokens = read_from(tokens)
print "parsed_tokens: "
p parsed_tokens

# coding: utf-8

# *** トークン生成 ***
def tokenize(s)
  s.gsub(/[()]/, ' \0 ').split
end
tokens = tokenize "(define plus1 (lambda (n) (+ n 1)))"
#=> ["(", "define", "plus1", "(", "lambda", "(", "n", ")", "(", "+", "n", "1", ")", ")", ")"]
print "tokens: "
p tokens
# パーサはまず読込んだプログラムの文字列をその構文要素であるトークン(token)に分割します。
# カッコの前後に空白を挿入してsplitによる分割がうまくいくように前処理している点がポイントです。
# String#gsubに正規表現を渡すことで両カッコの前処理を一度にしています。


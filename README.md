autocom
=======
This Ruby Gem introduces prediction trees, a data structure that suggests autocompletions for word prefixes.
It is related to the 'Trie' data structure (see, e.g., <http://en.wikipedia.org/wiki/Trie>).

The main advantage that prediction trees provide is the ability to efficiently report the k most likely
completions for a particular word prefix (or 'stub'), where k is a small integer (e.g., 8) that is chosen
when the tree is constructed.

A prediction tree is constructed from a set of unique words, where each has a relative frequency, such as
the number of times each word appears in some corpus.  If the total length of these words is n, then the
time to construct the prediction tree is O(n log n), and the query time is linear in the size of the
(at most) k autocompletions reported.

Written by Jeff Sember, January 2014.

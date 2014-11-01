bitext-tokaligner
=================

This script is a simple algorithm to align (at word level) a source sentence and its human-generated reference using a raw translation version as pivot. It was designed to extract new phrase pairs in a real-time post-editing context. Both its usability and its time consuming aspects make 'bitext-tokaligner' a suitable approach for this purpose.

Note that 'bitext-tokaligner' expects a single sentence on its standard input. Hence, if you want using it to align a "bitext", when the reviewing process is simulated for instance, use one line per sentence.

**-- How does it work?**

It's a 3-steps process:

**1.** The bitext-tokaligner needs to know for each word of a raw translation, which word of the source sentence is associated with.

To do so, using the Moses toolkit for the translation step, you must ask the decoder to print out the word-level alignments: `-alignment-output-file [src-to-trans.align]` (see [doc][2] for more details).

> Note that **this step is time-free** since the phrase table (binary or textual) includes word-to-word alignments between source and target phrases. Then Moses can report them in the output.


**2.** Compute the edit distance (Levenstein) between a raw translation and a reference, using the TER algorithm (Snover).

To do so, use [TERcpp][3], a c++ implementation of the TER designed by [Christophe Servan][4]:

    $PATH/tercpp-bin --noTxtIds --printAlignments -r [ref] -h [trans]

A file named `[trans].output.alignments` containing the TER informations will be created. Note that the bitext-tokaligner has been tested with TERcpp v0.6.2.

> This step is the most time-consuming part of the process. Nevertheless, TERcpp **requires less than 5 sec** to compute the edit-path over a test set containing 1,5k sentences pairs (about 35k words).

**3.** Finally, use the script 'bitext-tokalign.pl' on the previous alignment informations to deduce a word-level source-to-reference alignment, as follow:

    $PATH/bitext-tokalign.pl [src-to-trans.align] [trans-to-ref.align] > [src-to-ref.align]

> It was measured that 'bitext-tokalign.pl', applied on the same test set as step2, **requires less than 1 sec** for computing the src-to-ref alignment using both src-to-trans and trans-to-ref alignments.

**-- Reference**

If you use the bitext-tokaligner for your work, please cite this article in your publications:

Frederic Blain, Holger Schwenk, Jean Senellart, "Incremental Adaptation Using Translation Information and Post-Editing Analysis", Proceedings of the International Workshop on Spoken Language Translation (IWSLT), Hong-Kong, China, December 2012.

[1]: http://statmt.org/moses/ "Moses toolkit"
[2]: http://www.statmt.org/moses/?n=Moses.AdvancedFeatures#w2walignment "w2w alignment in Moses"
[3]: http://tercpp.sourceforge.net/ "TERcpp"
[4]: http://fr.linkedin.com/pub/christophe-servan/24/752/875 "Christophe Servan"


#ifndef _libxml2_h_
#define _libxml2_h_
#include <libxml2/libxml/tree.h>
#include <libxml2/libxml/xmlreader.h>
#include <libxml2/libxml/xpath.h>
#include <libxml2/libxml/xpathInternals.h>
#include <libxml2/libxml/HTMLparser.h>
#include <libxml2/libxml/parser.h>
#include <libxml2/libxml/entities.h>
#include <libxml2/libxml/SAX.h>
#include <libxml2/libxml/SAX2.h>

// libxml2 exposes xmlFree as a swappable global function-pointer
// *variable* (for custom allocators), which Swift 6 strict concurrency
// flags as shared mutable state on every read, even a single one-time
// capture. Calling it from a plain C function instead of reading the
// Swift-imported global sidesteps that check entirely — this wrapper
// itself is not a mutable variable from Swift's point of view.
static inline void perfectxml2_free(void *p) {
    xmlFree(p);
}
#endif

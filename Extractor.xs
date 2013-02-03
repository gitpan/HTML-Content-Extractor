#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "html.h"

typedef htmltag_t * HTML__Content__Extractor;

void clean_text(struct tree_entity *entities, struct lbuffer *lbuff) {
    if(lbuff->i < 0)
        return;
    
    long lsize = lbuff->i + 128;
    char *new_buff = (char *)malloc(sizeof(char) * lsize);
    memset(new_buff, 0, lbuff->i + 1);
    
    long i = 0;
    for (i = 0; i <= lbuff->i; i++) {
        if(lbuff->buff[i] != ' ' && lbuff->buff[i] != '\t' && lbuff->buff[i] != '\n')
            break;
    }
    
    long n = -1, count, next_i;
    while (i <= lbuff->i) {
        count = 0;
        
        switch (lbuff->buff[i]) {
            case '\n':
                for (i = i; i <= lbuff->i; i++) {
                    count++;
                    
                    if(lbuff->buff[i] != '\n') {
                        i--;
                        break;
                    }
                    else if(count <= 2) {
                        if(++n >= lsize) {
                            lsize += 128;
                            new_buff = realloc(new_buff, sizeof(char) * lsize);
                            memset(&new_buff[n], 0, 128);
                        }
                        
                        new_buff[n] = lbuff->buff[i];
                    }
                }
                
                break;
            case ' ':
                for (i = i; i <= lbuff->i; i++) {
                    count++;
                    
                    if(lbuff->buff[i] != ' ' && lbuff->buff[i] != '\t') {
                        i--;
                        break;
                    }
                    else if(count <= 1) {
                        if(++n >= lsize) {
                            lsize += 128;
                            new_buff = realloc(new_buff, sizeof(char) * lsize);
                            memset(&new_buff[n], 0, 128);
                        }
                        
                        new_buff[n] = ' ';
                    }
                }
                
                break;
            case '\t':
                for (i = i; i <= lbuff->i; i++) {
                    count++;
                    
                    if(lbuff->buff[i] != ' ' && lbuff->buff[i] != '\t') {
                        i--;
                        break;
                    }
                    else if(count <= 1) {
                        if(++n >= lsize) {
                            lsize += 128;
                            new_buff = realloc(new_buff, sizeof(char) * lsize);
                            memset(&new_buff[n], 0, 128);
                        }
                        
                        new_buff[n] = ' ';
                    }
                }
                
                break;
            case '&':
                next_i = i + 1;
                if(lbuff->buff[next_i] != '\0') {
                    if(lbuff->buff[next_i] == '#') {
                        char *lm = NULL;
                        int hex = lbuff->buff[next_i + 1] == 'x' || lbuff->buff[next_i + 1] == 'X';
                        
                        unsigned long cp = strtoul(&lbuff->buff[ (hex ? (next_i+2) : (next_i+1)) ], &lm, hex ? 16 : 10);
                        long end_pos = lm - &lbuff->buff[i];
                        
                        if(end_pos <= 2) {
                            if(++n >= lsize) {
                                lsize += 128;
                                new_buff = realloc(new_buff, sizeof(char) * lsize);
                                memset(&new_buff[n], 0, 128);
                            }
                            
                            new_buff[n] = lbuff->buff[i];
                            break;
                        }
                        
                        if(*lm == ';') {
                            i += end_pos;
                        } else {
                            i += end_pos - 1;
                        }
                        
                        if(cp <= 0x007Ful)
                        {
                            if(n + 1 >= lsize) {
                                lsize += 128;
                                new_buff = realloc(new_buff, sizeof(char) * lsize);
                                memset(&new_buff[n + 1], 0, 128);
                            }
                            
                            new_buff[n + 1] = (unsigned char)cp;
                            n++;
                        }
                        else if(cp <= 0x07FFul)
                        {
                            if(n + 2 >= lsize) {
                                lsize += 128;
                                new_buff = realloc(new_buff, sizeof(char) * lsize);
                                memset(&new_buff[n + 1], 0, 128);
                            }
                            
                            new_buff[n + 2] = (unsigned char)((2 << 6) | (cp & 0x3F));
                            new_buff[n + 1] = (unsigned char)((6 << 5) | (cp >> 6));
                            n += 2;
                        }
                        else if(cp <= 0xFFFFul)
                        {
                            if(n + 3 >= lsize) {
                                lsize += 128;
                                new_buff = realloc(new_buff, sizeof(char) * lsize);
                                memset(&new_buff[n + 1], 0, 128);
                            }
                            
                            new_buff[n + 3] = (unsigned char)(( 2 << 6) | ( cp       & 0x3F));
                            new_buff[n + 2] = (unsigned char)(( 2 << 6) | ((cp >> 6) & 0x3F));
                            new_buff[n + 1] = (unsigned char)((14 << 4) |  (cp >> 12));
                            n += 3;
                            
                        }
                        else if(cp <= 0x10FFFFul)
                        {
                            if(n + 4 >= lsize) {
                                lsize += 128;
                                new_buff = realloc(new_buff, sizeof(char) * lsize);
                                memset(&new_buff[n + 1], 0, 128);
                            }
                            
                            new_buff[n + 4] = (unsigned char)(( 2 << 6) | ( cp        & 0x3F));
                            new_buff[n + 3] = (unsigned char)(( 2 << 6) | ((cp >>  6) & 0x3F));
                            new_buff[n + 2] = (unsigned char)(( 2 << 6) | ((cp >> 12) & 0x3F));
                            new_buff[n + 1] = (unsigned char)((30 << 3) |  (cp >> 18));
                            n += 4;
                        }
                    }
                    else {
                        struct tree_entity *entity = check_entity(entities, &lbuff->buff[next_i]);
                        if(entity) {
                            int m = -1;
                            while(entity->value[++m]) {
                                if(++n >= lsize) {
                                    lsize += 128;
                                    new_buff = realloc(new_buff, sizeof(char) * lsize);
                                    memset(&new_buff[n], 0, 128);
                                }
                                
                                new_buff[n] = entity->value[m];
                            }
                            
                            i += entity->level + 1;
                            
                            if(lbuff->buff[i + 1] != '\0' && lbuff->buff[i + 1] == ';')
                                i++;
                        } else {
                            if(++n >= lsize) {
                                lsize += 128;
                                new_buff = realloc(new_buff, sizeof(char) * lsize);
                                memset(&new_buff[n], 0, 128);
                            }
                            
                            new_buff[n] = lbuff->buff[i];
                        }
                    }
                }
                
                break;
            
            default:
                if(++n >= lsize) {
                    lsize += 128;
                    new_buff = realloc(new_buff, sizeof(char) * lsize);
                    memset(&new_buff[n], 0, 128);
                }
                
                new_buff[n] = lbuff->buff[i];
                break;
        }
        
        i++;
    }
    
    for (i = n; i >= 0; i--) {
        if(new_buff[i] != ' ' && new_buff[i] != '\t' && new_buff[i] != '\n' && new_buff[i] != '\0') {
            new_buff[++n] = '\0';
            break;
        }
        
        n--;
    }
    
    free(lbuff->buff);
    lbuff->buff = new_buff;
    lbuff->i    = n;
}

void _add_to_lbuff(struct lbuffer *lbuff, char nc) {
    if(++lbuff->i == lbuff->buff_size) {
        lbuff->buff_size += 4096;
        lbuff->buff = (char *)realloc(lbuff->buff, sizeof(char) * lbuff->buff_size);
    }
    
    lbuff->buff[lbuff->i] = nc;
}

void get_text_without_element(struct tree_list *my_r, struct lbuffer *lbuff) {
    struct html_tree * tag = NULL;
    int element_p_id  = get_tag_id(my_r->tags, "p");
    
    long save_nco_pos = my_r->nco_pos;
    
    lbuff->buff = (char *)malloc(sizeof(char) * lbuff->buff_size);
    
    while ((tag = get_next_element_in_level(my_r))) {
        
        if(my_r->tags->type[ tag->tag_id ] == TYPE_TAG_BLOCK || my_r->tags->type[ tag->tag_id ] == TYPE_TAG_ONE) {
            _add_to_lbuff(lbuff, '\n');
            
            if(tag->tag_id == element_p_id) {
                _add_to_lbuff(lbuff, '\n');
            }
            
            continue;
        }
        
        if(my_r->tags->type[ tag->tag_id ] == TYPE_TAG_SIMPLE) {
            tag = get_next_element_in_level_skip_curr(my_r);
            
            if(tag == NULL)
                break;
            
            get_prev_element_in_level(my_r);
            continue;
        }
        
        if(my_r->tags->type[ tag->tag_id ] != TYPE_TAG_TEXT) {
            continue;
        }
        
        long il;
        for (il = tag->tag_body_start; il <= tag->tag_body_stop; il++) {
            if(my_r->html[il] != '\n')
                _add_to_lbuff(lbuff, my_r->html[il]);
        }
    }
    
    _add_to_lbuff(lbuff, '\0');
    
    my_r->nco_pos = save_nco_pos;
}

void _get_text_with_element_cl(struct tree_list *my_r, struct lbuffer *lbuff, char **elements, int ei_size) {
    struct html_tree * tag = NULL;
    int element_p_id  = get_tag_id(my_r->tags, "p");
    int element_br_id  = get_tag_id(my_r->tags, "br");
    
    while ((tag = get_next_element_in_level(my_r))) {
        
        int is, it, ip = -1, in = -1;
        for (is = 0; is <= ei_size; is++) {
            it = -1;
            while (elements[is][++it]) {
                in = it + 1;
                if((my_r->tags->name[tag->tag_id][in] == '\0' && elements[is][in] != '\0') ||
                   (my_r->tags->name[tag->tag_id][in] != '\0' && elements[is][in] == '\0') ||
                   my_r->tags->name[tag->tag_id][it] != elements[is][it]
                ) {
                    break;
                }
                else if(my_r->tags->name[tag->tag_id][in] == '\0' && elements[is][in] == '\0') {
                    ip = tag->tag_id;
                    break;
                }
            }
        }
        
        if(ip != -1) {
            long il;
            for (il = tag->tag_start; il < tag->tag_body_start; il++) {
                _add_to_lbuff(lbuff, my_r->html[il]);
            }
            
            long save_nco_pos = my_r->nco_pos;
            long save_cur_pos = my_r->cur_pos;
            my_r->nco_pos = tag->id;
            my_r->cur_pos = tag->id;
            
            _get_text_with_element_cl(my_r, lbuff, elements, ei_size);
            
            for (il = tag->tag_body_stop + 1; il <= tag->tag_stop; il++) {
                _add_to_lbuff(lbuff, my_r->html[il]);
            }
            
            my_r->nco_pos = save_nco_pos;
            my_r->cur_pos = save_cur_pos;
            
            if(get_next_element_in_level_skip_curr(my_r) == NULL)
                break;
            
            get_prev_element_in_level(my_r);
            
            //continue;
        }
        
        if(my_r->tags->type[ tag->tag_id ] == TYPE_TAG_BLOCK || my_r->tags->type[ tag->tag_id ] == TYPE_TAG_ONE) {
            if((tag->tag_id == element_br_id && ip != element_br_id) || (my_r->tags->type[ tag->tag_id ] == TYPE_TAG_BLOCK))
                _add_to_lbuff(lbuff, '\n');
            
            if(tag->tag_id == element_p_id && ip != element_p_id) {
                _add_to_lbuff(lbuff, '\n');
            }
            
            continue;
        }
        
        if(my_r->tags->type[ tag->tag_id ] == TYPE_TAG_SIMPLE) {
            if(get_next_element_in_level_skip_curr(my_r) == NULL)
                break;
            
            get_prev_element_in_level(my_r);
            continue;
        }
        
        if(my_r->tags->type[ tag->tag_id ] != TYPE_TAG_TEXT) {
            continue;
        }
        
        long il;
        for (il = tag->tag_body_start; il <= tag->tag_body_stop; il++) {
            if(my_r->html[il] != '\n')
                _add_to_lbuff(lbuff, my_r->html[il]);
        }
    }
}

void get_text_with_element(struct tree_list *my_r, struct lbuffer *lbuff, char **elements, int ei_size) {
    long save_nco_pos = my_r->nco_pos;
    
    lbuff->buff = (char *)malloc(sizeof(char) * lbuff->buff_size);
    
    _get_text_with_element_cl(my_r, lbuff, elements, ei_size);
    _add_to_lbuff(lbuff, '\0');
    
    my_r->nco_pos = save_nco_pos;
}

void get_raw_text(struct tree_list *my_r, struct lbuffer *lbuff) {
    struct html_tree * tag = get_curr_element(my_r);
    
    lbuff->i = -1;
    lbuff->buff_size = (tag->tag_stop - tag->tag_start) + 1;
    lbuff->buff = (char *)malloc(sizeof(char) * lbuff->buff_size);
    
    long il;
    for (il = tag->tag_start; il <= tag->tag_stop; il++) {
        lbuff->buff[++lbuff->i] = my_r->html[il];
    }
    
    lbuff->buff[++lbuff->i] = '\0';
}

int _check_img_size(char *str) {
    int rv = 0;
    
    if(str){
        while ( *str ) {
            if(*str <= '9' && *str >= '0') {
                rv = (rv * 10) + (*str - '0');
            }
            else if(rv != 0) {
                rv = 0;
                break;
            }
            
            str++;
        }
    }
    
    return rv;
}

void get_text_images_href(struct tree_list *my_r, struct mlist *buff, int inc) {
    struct html_tree * tag = NULL;
    
    long save_nco_pos = my_r->nco_pos;
    
    if(inc == 0)
        buff->buff = (char **)malloc(sizeof(char*) * buff->buff_size);
    
    while ((tag = get_next_element_in_level(my_r))) {
        if(my_r->tags->ai[ tag->tag_id ] == AI_IMG) {
            struct mem_params * param = find_param_by_key_in_element(&my_r->my[tag->my_id], "src");
            if(param == NULL)
                continue;
            
            struct mem_params * width = find_param_by_key_in_element(&my_r->my[tag->my_id], "width");
            if( width == NULL || _check_img_size(width->value) >= 100 ) {
                long i, m; int is_clone = 0;
                
                for (i = 0; i <= buff->i; i++) {
                    for (m = 0; m <= param->lvalue; m++) {
                        if(((buff->buff[i][m] == '\0' && param->value[m] != '\0') && (buff->buff[i][m] != '\0' && param->value[m] == '\0')) ||
                           buff->buff[i][m] != param->value[m]
                        ) {
                            break;
                        }
                        else if(param->value[m] == '\0' && buff->buff[i][m] == '\0') {
                            is_clone = 1;
                            break;
                        }
                    }
                    
                    if(is_clone == 1)
                        break;
                }
                
                if(is_clone == 0 && param->lvalue > -1) {
                    buff->buff[++buff->i] = (char *)malloc(sizeof(char) * param->lvalue + 1);
                    
                    unsigned int sl = 0;
                    while (param->lvalue >= sl) {
                        buff->buff[buff->i][sl] = param->value[sl];
                        sl++;
                    }
                }
            }
        }
    }
    
    if(inc < 1) {
        struct html_tree *curr_pos = get_curr_element(my_r);
        get_prev_element_curr_level(my_r);
        get_text_images_href(my_r, buff, ++inc);
        set_position(my_r, curr_pos);
    }
    
    my_r->nco_pos = save_nco_pos;
}

struct html_tree * check_html(struct tree_list *my_r, struct max_element *max) {
    struct html_tree * tag;
    long i = -1;
    long count_words = 0;
    
    while((tag = get_child_n(my_r, ++i))) {
        if(my_r->tags->ai[ tag->tag_id ] == AI_TEXT) {
            count_words += tag->count_word;
        }
    }
    
    if(max->count_words < count_words) {
        max->count_words = count_words;
        max->element = get_curr_element(my_r);
    }
    
    i = -1;
    while((tag = get_child(my_r, ++i))) {
        if(my_r->tags->ai[ tag->tag_id ] == AI_LINK)
            continue;
        
        check_html(my_r, max);
        set_position(my_r, tag);
        get_parent(my_r);
    }
    
    return max->element;
}

int init_tags(struct tags *tags) {
    if(tags->csize > -1)
        return -1;
    
    tags->csize = 2048;
    
    tags->name     = (char **)malloc(sizeof(char *) * tags->csize);
    
    tags->preority = (int *)malloc(sizeof(int) * tags->csize);
    tags->type     = (int *)malloc(sizeof(int) * tags->csize);
    tags->extra    = (int *)malloc(sizeof(int) * tags->csize);
    tags->ai       = (int *)malloc(sizeof(int) * tags->csize);
    
    tags->index.tag_id    = (long **)malloc(sizeof(long *) * tags->csize);
    tags->index.tag_count = (int *)malloc(sizeof(int) * tags->csize);
    tags->index.tag_csize = (int *)malloc(sizeof(int) * tags->csize);
    
    // default tags !!!NOT EDIT!!!
    add_tag_R(tags, ""      , 0, 0  , TYPE_TAG_TEXT  , 0, AI_NULL);
    // end default tags
    
    add_tag_R(tags, "html"  , 4, 200, TYPE_TAG_BLOCK , 0, AI_NULL);
    add_tag_R(tags, "head"  , 4, 200, TYPE_TAG_BLOCK , 0, AI_NULL);
    add_tag_R(tags, "body"  , 4, 200, TYPE_TAG_BLOCK , 0, AI_NULL);
    add_tag_R(tags, "div"   , 3, 50 , TYPE_TAG_BLOCK , 0, AI_NULL);
    add_tag_R(tags, "p"     , 1, 0  , TYPE_TAG_BLOCK , EXTRA_TAG_CLOSE_IF_BLOCK, AI_TEXT);
    add_tag_R(tags, "table" , 5, 55 , TYPE_TAG_BLOCK , 0, AI_NULL);
    add_tag_R(tags, "tbody" , 5, 54 , TYPE_TAG_BLOCK , 0, AI_NULL);
    add_tag_R(tags, "tr"    , 2, 53 , TYPE_TAG_BLOCK , EXTRA_TAG_CLOSE_IF_SELF, AI_NULL);
    add_tag_R(tags, "th"    , 2, 52 , TYPE_TAG_BLOCK , EXTRA_TAG_CLOSE_IF_SELF, AI_NULL);
    add_tag_R(tags, "td"    , 2, 52 , TYPE_TAG_BLOCK , EXTRA_TAG_CLOSE_IF_SELF, AI_NULL);
    add_tag_R(tags, "ul"    , 2, 40 , TYPE_TAG_BLOCK , 0, AI_NULL);
    add_tag_R(tags, "li"    , 2, 39 , TYPE_TAG_BLOCK , 0, AI_TEXT);
    
    add_tag_R(tags, "nobr"    , 4, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "a"       , 1, 0 , TYPE_TAG_INLINE  , 0, AI_LINK);
    add_tag_R(tags, "abbr"    , 4, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "acronym" , 7, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "b"       , 1, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "basefont", 8, 0 , TYPE_TAG_ONE     , 0, AI_TEXT);
    add_tag_R(tags, "bdo"     , 3, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "big"     , 3, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "cite"    , 4, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "code"    , 4, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "dfn"     , 3, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "em"      , 2, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "font"    , 4, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "i"       , 1, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "kbd"     , 3, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "label"   , 5, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "q"       , 1, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "s"       , 1, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "samp"    , 4, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "select"  , 6, 0 , TYPE_TAG_INLINE  , 0, AI_NULL);
    add_tag_R(tags, "small"   , 5, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "span"    , 4, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "strike"  , 6, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "strong"  , 6, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "sub"     , 3, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "sup"     , 3, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "tt"      , 2, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "u"       , 1, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    add_tag_R(tags, "var"     , 3, 0 , TYPE_TAG_INLINE  , 0, AI_TEXT);
    
    add_tag_R(tags, "h1"    , 2, 0 , TYPE_TAG_BLOCK , 0, AI_TEXT);
    add_tag_R(tags, "h2"    , 2, 0 , TYPE_TAG_BLOCK , 0, AI_TEXT);
    add_tag_R(tags, "h3"    , 2, 0 , TYPE_TAG_BLOCK , 0, AI_TEXT);
    add_tag_R(tags, "h4"    , 2, 0 , TYPE_TAG_BLOCK , 0, AI_TEXT);
    add_tag_R(tags, "h5"    , 2, 0 , TYPE_TAG_BLOCK , 0, AI_TEXT);
    add_tag_R(tags, "h6"    , 2, 0 , TYPE_TAG_BLOCK , 0, AI_TEXT);
    add_tag_R(tags, "iframe", 6, 0 , TYPE_TAG_BLOCK , 0, AI_NULL);
    
    add_tag_R(tags, "form"    , 4, 0 , TYPE_TAG_BLOCK  , 0, AI_NULL);
    add_tag_R(tags, "textarea", 8, 0 , TYPE_TAG_INLINE , 0, AI_NULL);
    
    add_tag_R(tags, "meta"    , 4, 0  , TYPE_TAG_ONE   , 0, AI_NULL);
    add_tag_R(tags, "area"    , 4, 0  , TYPE_TAG_ONE   , 0, AI_NULL);
    add_tag_R(tags, "base"    , 4, 0  , TYPE_TAG_ONE   , 0, AI_NULL);
  //add_tag_R(tags, "basefont", 8, 0  , TYPE_TAG_ONE   , 0, AI_TEXT);
    add_tag_R(tags, "br"      , 2, 0  , TYPE_TAG_ONE   , 0, AI_TEXT);
    add_tag_R(tags, "col"     , 3, 0  , TYPE_TAG_ONE   , 0, AI_NULL);
    add_tag_R(tags, "frame"   , 5, 0  , TYPE_TAG_ONE   , 0, AI_NULL);
    add_tag_R(tags, "hr"      , 2, 0  , TYPE_TAG_ONE   , 0, AI_NULL);
    add_tag_R(tags, "img"     , 3, 0  , TYPE_TAG_ONE   , 0, AI_IMG );
    add_tag_R(tags, "input"   , 5, 0  , TYPE_TAG_ONE   , 0, AI_NULL);
    add_tag_R(tags, "isindex" , 7, 0  , TYPE_TAG_ONE   , 0, AI_NULL);
    add_tag_R(tags, "link"    , 4, 0  , TYPE_TAG_ONE   , 0, AI_NULL);
    add_tag_R(tags, "param"   , 5, 0  , TYPE_TAG_ONE   , 0, AI_NULL);
    add_tag_R(tags, "!doctype", 8, 0  , TYPE_TAG_ONE   , 0, AI_NULL);
    
    add_tag_R(tags, "script", 6, 0, TYPE_TAG_SIMPLE, 0, AI_NULL);
    add_tag_R(tags, "style" , 5, 0, TYPE_TAG_SIMPLE, 0, AI_NULL);
    
    return tags->csize;
}

void html_tree(struct tree_list *my_r)
{
    char *html = my_r->html;
    struct tags *tags = my_r->tags;
    
    init_tags(tags);
    
    long my_buff = -1, my_real_buff = -1;
    long my_buff_size = 1024 * 10;
    struct mem_tag* my = (struct mem_tag *)malloc(sizeof(struct mem_tag) * my_buff_size);
    
    long html_tree_buff = 0, html_tree_buff_size = 1024 * 10;
    struct html_tree* html_tree = (struct html_tree *)malloc(sizeof(struct html_tree) * html_tree_buff_size);
    
    int tag_ol = 0;
    int index_ol_size = 1024;
    long *index_ol = (long *)malloc(sizeof(long) * index_ol_size);
    
    html_tree[ html_tree_buff ].tag_id = -1;
    html_tree[ html_tree_buff ].my_id  = -1;
    
    html_tree[ html_tree_buff ].tag_body_start = 0;
    html_tree[ html_tree_buff ].tag_body_stop  = -1;
    
    html_tree[ html_tree_buff ].tag_start = 0;
    html_tree[ html_tree_buff ].tag_stop  = -1;
    
    html_tree[ html_tree_buff ].count_element    = 0;
    html_tree[ html_tree_buff ].count_element_in = 0;
    html_tree[ html_tree_buff ].count_word       = 0;
    
    memset(html_tree[ html_tree_buff ].counts, 0, AI_BUFF);
    memset(html_tree[ html_tree_buff ].counts_in, 0, AI_BUFF);
    
    index_ol[tag_ol] = html_tree_buff;
    html_tree[ html_tree_buff ].inc = tag_ol;
    
    long i = 0, pos = 0, count_tag = 1;
    char nc; long next_tag = 0;
    long text_position = -1;
    
    int is_comment = 0; int spl_word = 0;
    
    while( (nc = html[i++]) ) {
        if(nc == '>' && (
           (my_buff != -1 && (my[my_buff].qo == '\0' || my[my_buff].qo == ' ')) ||
           (nc == '>' && is_comment == 1))
           ) {
            
            if(is_comment == 1) {
                if(html[i-2] == '-' && html[i-3] == '-') {
                    is_comment = 0;
                    pos = 0;
                }
                continue;
            }
            
            if(my_buff == -1)
                continue;
            
            if(html[ my[my_buff].start_otag ] == '/') {
                if(my[my_buff].stop_otag == 0)
                    my[my_buff].stop_otag = i - 2;
                
                int tag_id = cmp_tags(tags, html, &my[my_buff], 1);
                
                if(tag_ol > -1 && tag_id > -1) {
                    int ti; int is_open = 0;
                    for(ti = tag_ol; ti >= 1; ti--) {
                        if(tags->preority[ html_tree[ index_ol[ti] ].tag_id ] > tags->preority[tag_id]){
                            break;
                        }
                        
                        if(tag_id == html_tree[ index_ol[ti] ].tag_id) {
                            is_open = 1;
                            break;
                        }
                    }
                    
                    if(html_tree_buff > 0) {
                        if(tags->type[ html_tree[ index_ol[tag_ol] ].tag_id ] == TYPE_TAG_SIMPLE &&
                           html_tree[ index_ol[tag_ol] ].tag_body_stop == -1 && tag_id != html_tree[ index_ol[tag_ol] ].tag_id
                        ) {
                            pos      = 0;
                            next_tag = 0;
                            my_buff--;
                            continue;
                        }
                    }
                    
                    if(is_open == 1) {
                        if( tag_id != html_tree[ index_ol[tag_ol] ].tag_id || tags->type[html_tree[ index_ol[tag_ol] ].tag_id] == TYPE_TAG_SIMPLE) {
                            
                            int ti;
                            for(ti = tag_ol; ti >= 1; ti--) {
                                if(tags->type[ html_tree[ index_ol[ti] ].tag_id ] == TYPE_TAG_ONE && html_tree[ index_ol[ti] ].tag_body_stop == -1) {
                                    html_tree[ index_ol[ti] ].tag_body_stop = html_tree[ index_ol[ti] ].tag_body_start;
                                    html_tree[ index_ol[ti] ].tag_stop = html_tree[ index_ol[ti] ].tag_body_start - 1;
                                    
                                    html_tree[ index_ol[ti - 1] ].count_element_in += html_tree[ index_ol[ti] ].count_element_in;
                                    
                                    int si;
                                    for(si = 0; si < AI_BUFF; si++) {
                                        html_tree[ index_ol[ti-1] ].counts_in[ si ] += html_tree[ index_ol[ti] ].counts_in[ si ];
                                    }
                                    
                                    tag_ol--;
                                    continue;
                                }
                                
                                if(tags->type[ html_tree[ index_ol[ti] ].tag_id ] == TYPE_TAG_SIMPLE && html_tree[ index_ol[ti] ].tag_body_stop == -1) {
                                    html_tree[ index_ol[ti] ].tag_body_stop = my[ my_buff ].start_otag - 2;
                                    html_tree[ index_ol[ti] ].tag_stop = i - 1;
                                }
                                else if(tags->preority[ html_tree[ index_ol[ti] ].tag_id ] > tags->preority[tag_id]){
                                    break;
                                }
                                else if(tag_id == html_tree[ index_ol[ti] ].tag_id && html_tree[ index_ol[ti] ].tag_body_stop == -1) {
                                    html_tree[ index_ol[ti] ].tag_body_stop = my[ my_buff ].start_otag - 2;
                                    html_tree[ index_ol[ti] ].tag_stop = i - 1;
                                    
                                    html_tree[ index_ol[ti - 1] ].count_element_in += html_tree[ index_ol[ti] ].count_element_in;
                                    
                                    int si;
                                    for(si = 0; si < AI_BUFF; si++) {
                                        html_tree[ index_ol[ti - 1] ].counts_in[ si ] += html_tree[ index_ol[ti] ].counts_in[ si ];
                                    }
                                    
                                    tag_ol--;
                                    break;
                                }
                                else if(html_tree[ index_ol[ti] ].tag_body_stop == -1){
                                    html_tree[ index_ol[ti] ].tag_body_stop = my[ my_buff ].start_otag - 2;
                                    html_tree[ index_ol[ti] ].tag_stop = i - 1;
                                }
                                
                                if(tags->preority[ html_tree[ index_ol[ti] ].tag_id ] <= tags->preority[tag_id]) {
                                    html_tree[ index_ol[ti] ].tag_body_stop = my[ my_buff ].start_otag - 2;
                                    html_tree[ index_ol[ti] ].tag_stop = i - 1;
                                }
                                
                                html_tree[ index_ol[ti - 1] ].count_element_in += html_tree[ index_ol[ti] ].count_element_in;
                                
                                int si;
                                for(si = 0; si < AI_BUFF; si++) {
                                    html_tree[ index_ol[ti - 1] ].counts_in[ si ] += html_tree[ index_ol[ti] ].counts_in[ si ];
                                }
                                
                                tag_ol--;
                            }
                        } else {
                            html_tree[ index_ol[tag_ol] ].tag_body_stop = my[ my_buff ].start_otag - 2;
                            html_tree[ index_ol[tag_ol] ].tag_stop = i - 1;
                            
                            html_tree[ index_ol[tag_ol - 1] ].count_element_in += html_tree[ index_ol[tag_ol] ].count_element_in;
                            
                            int si;
                            for(si = 0; si < AI_BUFF; si++) {
                                html_tree[ index_ol[tag_ol - 1] ].counts_in[ si ] += html_tree[ index_ol[tag_ol] ].counts_in[ si ];
                            }
                            
                            tag_ol--;
                        }
                    }
                }
                
                my_buff--;
            }
            else {
                if(my[my_buff].stop_otag == 0) {
                    my[my_buff].stop_otag = i - 2;
                }
                
                if(html_tree_buff > 0) {
                    if(tags->type[ html_tree[ index_ol[tag_ol] ].tag_id ] == TYPE_TAG_SIMPLE && html_tree[ index_ol[tag_ol] ].tag_stop == -1) {
                        pos      = 0;
                        next_tag = 0;
                        continue;
                    }
                }
                
                int tag_id = cmp_tags(tags, html, &my[my_buff], 0);
                
                tags->index.tag_count[tag_id]++;
                if(tags->index.tag_count[tag_id] >= tags->index.tag_csize[tag_id]) {
                    tags->index.tag_csize[tag_id] += 128;
                    tags->index.tag_id[tag_id] = (long *)realloc(tags->index.tag_id[tag_id], sizeof(long) * tags->index.tag_csize[tag_id]);
                }
                
                html_tree_buff++;
                
                tags->index.tag_id[tag_id][ tags->index.tag_count[tag_id] ] = html_tree_buff;
                
                if(html_tree_buff == html_tree_buff_size) {
                    html_tree_buff_size += 1024;
                    html_tree = (struct html_tree *)realloc(html_tree, sizeof(struct html_tree) * html_tree_buff_size);
                }
                
                html_tree[ html_tree_buff ].id     = html_tree_buff;
                html_tree[ html_tree_buff ].tag_id = tag_id;
                html_tree[ html_tree_buff ].my_id  = my_buff;
                
                html_tree[ html_tree_buff ].tag_body_start = i;
                html_tree[ html_tree_buff ].tag_body_stop  = -1;
                
                html_tree[ html_tree_buff ].tag_start = my[my_buff].start_otag - 1;
                html_tree[ html_tree_buff ].tag_stop  = -1;
                
                html_tree[ html_tree_buff ].count_element    = 0;
                html_tree[ html_tree_buff ].count_element_in = 0;
                html_tree[ html_tree_buff ].count_word       = 0;
                
                memset(html_tree[ html_tree_buff ].counts, 0, AI_BUFF);
                memset(html_tree[ html_tree_buff ].counts_in, 0, AI_BUFF);
                
                if(html_tree_buff > 0) {
                    int ti; int tag_ool = tag_ol;
                    for(ti = tag_ool; ti >= 1; ti--) {
                        if(html_tree[ index_ol[ti] ].tag_body_stop != -1){
                            continue;
                        }
                        
                        if(tags->type[ html_tree[ html_tree_buff ].tag_id ] == TYPE_TAG_BLOCK) {
                            if(tags->extra[ html_tree[ index_ol[ti] ].tag_id ] == EXTRA_TAG_CLOSE_IF_BLOCK) {
                                html_tree[ index_ol[ti] ].tag_body_stop = my[ my_buff ].start_otag - 2;
                                html_tree[ index_ol[ti] ].tag_stop = i - 1;
                                
                                tag_ol = html_tree[ index_ol[ti] ].inc - 1;
                                
                                html_tree[ index_ol[ti - 1] ].count_element_in += html_tree[ index_ol[ti] ].count_element_in;
                                
                                int si;
                                for(si = 0; si < AI_BUFF; si++) {
                                    html_tree[ index_ol[ti - 1] ].counts_in[ si ] += html_tree[ index_ol[ti] ].counts_in[ si ];
                                }
                            }
                            else if(tags->type[ html_tree[ index_ol[ti] ].tag_id ] == TYPE_TAG_INLINE) {
                                html_tree[ index_ol[ti] ].tag_body_stop = my[ my_buff ].start_otag - 2;
                                html_tree[ index_ol[ti] ].tag_stop = i - 1;
                                
                                tag_ol = html_tree[ index_ol[ti] ].inc - 1;
                                
                                html_tree[ index_ol[ti - 1] ].count_element_in += html_tree[ index_ol[ti] ].count_element_in;
                                
                                int si;
                                for(si = 0; si < AI_BUFF; si++) {
                                    html_tree[ index_ol[ti - 1] ].counts_in[ si ] += html_tree[ index_ol[ti] ].counts_in[ si ];
                                }
                            }
                        }
                    }
                }
                
                tag_ol++;
                
                if(tag_ol == index_ol_size) {
                    index_ol_size += 1024;
                    index_ol = (long *)realloc(index_ol, sizeof(long) * index_ol_size);
                }
                
                index_ol[tag_ol] = html_tree_buff;
                html_tree[ html_tree_buff ].inc = tag_ol;
                
                if(tag_ol > 0) {
                    html_tree[ index_ol[tag_ol - 1] ].count_element++;
                    html_tree[ index_ol[tag_ol - 1] ].count_element_in++;
                    
                    html_tree[ index_ol[tag_ol - 1] ].counts[ tags->ai[ html_tree[ html_tree_buff ].tag_id ] ]++;
                    html_tree[ index_ol[tag_ol - 1] ].counts_in[ tags->ai[ html_tree[ html_tree_buff ].tag_id ] ]++;
                }
                
                if(tags->type[ tag_id ] == TYPE_TAG_ONE) {
                    html_tree[ html_tree_buff ].tag_body_stop = html_tree[ html_tree_buff ].tag_body_start;
                    html_tree[ html_tree_buff ].tag_stop = i - 1;
                    tag_ol--;
                }
                
                if(my[my_buff].lparams > -1) {
                    if(my[my_buff].params[ my[my_buff].lparams ].lkey == 1 && my[my_buff].params[ my[my_buff].lparams ].key[0] == '/') {
                        free(my[my_buff].params[ my[my_buff].lparams ].key);
                        free(my[my_buff].params[ my[my_buff].lparams ].value);
                        
                        my[my_buff].lparams--;
                    }
                }
            }
            
            pos      = 0;
            next_tag = 0;
            
            continue;
        }
        
        switch (pos) {
            case 0:
                if(nc == '<' && ((html[i] >= 'a' && html[i] <= 'z') || (html[i] >= 'A' && html[i] <= 'Z') || html[i] == '/' || html[i] == '!')) {
                    if(html_tree[ index_ol[tag_ol] ].tag_id != -1 && tags->type[ html_tree[ index_ol[tag_ol] ].tag_id ] == TYPE_TAG_SIMPLE &&
                       html_tree[ index_ol[tag_ol] ].tag_stop == -1
                    ) {
                        if(html[i] == '!' && html[i+1] == '-' && html[i+2] == '-'){
                            is_comment = 1;
                            pos = 6;
                            break;
                        }
                        
                        int tl = 0, is_on = 1; long tu = 0;
                        while (tags->name[ html_tree[ index_ol[tag_ol] ].tag_id ][++tl]) {
                            tu = tl + i + 1;
                            if(tags->name[ html_tree[ index_ol[tag_ol] ].tag_id ][tl] != html[tu]) {
                                is_on = 0;
                                break;
                            }
                            else if(html[tu] == '\0') {
                                is_on = 0;
                                break;
                            }
                        }
                        
                        if(is_on == 0) {
                            break;
                        }
                    }
                    
                    if(html_tree[ html_tree_buff ].tag_id == DEFAULT_TAG_ID && html_tree[ html_tree_buff ].tag_body_stop == -1) {
                        html_tree[ html_tree_buff ].tag_body_stop  = i - 2;
                        html_tree[ html_tree_buff ].tag_stop = html_tree[ html_tree_buff ].tag_body_stop;
                    }
                    
                    text_position = -1;
                    
                    if(html[i] == '!' && html[i+1] == '-' && html[i+2] == '-'){
                        is_comment = 1;
                        pos = 6;
                        break;
                    }
                    
                    my_buff++;
                    my_real_buff = my_buff;
                    
                    if(count_tag != my_buff) {
                        count_tag = my_buff;
                        
                        if(my_buff_size < my_buff) {
                            my_buff_size += 1024;
                            my = (struct mem_tag *)realloc(my, sizeof(struct mem_tag) * my_buff_size);
                        }
                        
                        my[my_buff].lparams_size = 256;
                        my[my_buff].params = (struct mem_params *)malloc(sizeof(struct mem_params) * my[my_buff].lparams_size);
                    }
                    
                    my[my_buff].stop_otag = 0;
                    
                    my[my_buff].qo = '\0';
                    my[my_buff].qol = 0;
                    
                    my[my_buff].lparams = -1;
                    
                    next_tag = 0;
                    
                    pos = 1;
                    my[my_buff].start_otag = i;
                    
                    spl_word = 0;
                }
                else {
                    if(text_position == -1)
                        text_position = i - 1;
                    
                    if(nc != ' ' && nc != '\n' && nc != '\t' && (html_tree[ html_tree_buff ].tag_id != DEFAULT_TAG_ID ||
                        (html_tree[ html_tree_buff ].tag_id == DEFAULT_TAG_ID && html_tree[ html_tree_buff ].tag_body_stop != -1)
                    )) {
                        
                        html_tree_buff++;
                        html_tree[ html_tree_buff ].id     = html_tree_buff;
                        
                        html_tree[ html_tree_buff ].tag_id = DEFAULT_TAG_ID;
                        html_tree[ html_tree_buff ].my_id  = -1;
                        
                        html_tree[ html_tree_buff ].tag_body_start = text_position;
                        html_tree[ html_tree_buff ].tag_body_stop  = -1;
                        
                        html_tree[ html_tree_buff ].tag_start = html_tree[ html_tree_buff ].tag_body_start;
                        html_tree[ html_tree_buff ].tag_stop  = -1;
                        
                        html_tree[ html_tree_buff ].count_element    = 0;
                        html_tree[ html_tree_buff ].count_element_in = 0;
                        html_tree[ html_tree_buff ].count_word       = 0;
                        
                        html_tree[ html_tree_buff ].inc              = html_tree[ index_ol[tag_ol] ].inc + 1;
                        
                        memset(html_tree[ html_tree_buff ].counts, 0, AI_BUFF);
                        memset(html_tree[ html_tree_buff ].counts_in, 0, AI_BUFF);
                    }
                    
                    if(spl_word == 0 && nc != ' ' && nc != '\n' && nc != '\t') {
                        html_tree[ index_ol[tag_ol] ].count_word++;
                        spl_word = 1;
                    }
                    else if(nc == ' ' || nc == '\n' || nc == '\t'){
                        spl_word = 0;
                    }
                }
                
                break;
                
            case 1:
                if(nc == ' ' || nc == '\t' || nc == '\n' || (my[my_buff].start_otag != i-1 && nc == '/')) {
                    my[my_buff].stop_otag = i - 2;
                    
                    if(html[ my[my_buff].start_otag ] == '/') {
                        pos = 6;
                        break;
                    }
                    
                    pos = 2;
                }
                
                break;
                
            case 2:
                if(nc == '/')
                    break;
                
                if( (nc != ' ' && nc != '\t' && nc != '\n' && nc != '=') || (nc == '=' && next_tag != my[my_buff].lparams) ) {
                    if(next_tag != my[my_buff].lparams) {
                        my[my_buff].lparams++;
                        
                        if(my[my_buff].lparams > my[my_buff].lparams_size) {
                            my[my_buff].lparams_size += 256;
                            my[my_buff].params = (struct mem_params *)realloc(my[my_buff].params, sizeof(struct mem_params) * my[my_buff].lparams_size);
                        }
                        
                        my[my_buff].params[my[my_buff].lparams].lkey_size = 1024;
                        my[my_buff].params[my[my_buff].lparams].lvalue_size = 1024;
                        my[my_buff].params[my[my_buff].lparams].lkey   = 0;
                        my[my_buff].params[my[my_buff].lparams].lvalue = 0;
                        
                        my[my_buff].params[my[my_buff].lparams].key   = (char *)malloc(sizeof(char) * my[my_buff].params[my[my_buff].lparams].lkey_size);
                        my[my_buff].params[my[my_buff].lparams].value = (char *)malloc(sizeof(char) * my[my_buff].params[my[my_buff].lparams].lvalue_size);
                    }
                    
                    if( my[my_buff].params[my[my_buff].lparams].lkey >= my[my_buff].params[my[my_buff].lparams].lkey_size ) {
                        my[my_buff].params[my[my_buff].lparams].lkey_size += 1024;
                        my[my_buff].params[my[my_buff].lparams].key = (char *)realloc(my[my_buff].params[my[my_buff].lparams].key, my[my_buff].params[my[my_buff].lparams].lkey_size * sizeof(char));
                    }
                    
                    my[my_buff].params[my[my_buff].lparams].key[ my[my_buff].params[my[my_buff].lparams].lkey++ ] = nc;
                    break;
                }
                else if(next_tag == my[my_buff].lparams && my[my_buff].params[my[my_buff].lparams].lkey != 0) {
                    if( my[my_buff].params[my[my_buff].lparams].lkey >= my[my_buff].params[my[my_buff].lparams].lkey_size ) {
                        my[my_buff].params[my[my_buff].lparams].lkey_size += 1024;
                        my[my_buff].params[my[my_buff].lparams].key = (char *)realloc(my[my_buff].params[my[my_buff].lparams].key, my[my_buff].params[my[my_buff].lparams].lkey_size * sizeof(char));
                    }
                    
                    my[my_buff].params[my[my_buff].lparams].key[ my[my_buff].params[my[my_buff].lparams].lkey++ ] = '\0';
                    pos = 3;
                }
                
            case 3:
                if(nc == ' ' || nc == '\t' || nc == '\n' || nc == '/') {
                    break;
                }
                else if( nc == '=' ) {
                    pos = 4;
                } else {
                    i--;
                    
                    if(next_tag == my[my_buff].lparams){
                        my[my_buff].params[my[my_buff].lparams].value[0] = '\0';
                        next_tag++;
                    }
                    
                    my[my_buff].qo = '\0';
                    my[my_buff].qol = 0;
                    
                    pos = 2;
                }
                break;
                
            case 4:
                if(my[my_buff].qo == '\0' && (nc == ' ' || nc == '\t' || nc == '\n')) {
                    break;
                }
                else if(my[my_buff].qo == '\0' && (nc != ' ' && nc != '\t' && nc != '\n' && nc != '"' && nc != '\'')) {
                    my[my_buff].qo = ' ';
                }
                
                if(my[my_buff].qo == '\0') {
                    if(nc == '"') {
                        my[my_buff].qo = '"';
                    }
                    else if(nc == '\'') {
                        my[my_buff].qo = '\'';
                    }
                } else {
                    if( my[my_buff].params[my[my_buff].lparams].lvalue >= my[my_buff].params[my[my_buff].lparams].lvalue_size ) {
                        my[my_buff].params[my[my_buff].lparams].lvalue_size += 1024;
                        my[my_buff].params[my[my_buff].lparams].value = (char *)realloc(my[my_buff].params[my[my_buff].lparams].value, my[my_buff].params[my[my_buff].lparams].lvalue_size * sizeof(char));
                    }
                    
                    if((my[my_buff].qo == ' ' && (nc == ' ' || nc == '\t' || nc == '\n')) || (nc == my[my_buff].qo && fmod(my[my_buff].qol,2) == 0)) {
                        
                        pos = 2;
                        my[my_buff].params[my[my_buff].lparams].value[my[my_buff].params[my[my_buff].lparams].lvalue++] = '\0';
                        my[my_buff].qo = '\0';
                        my[my_buff].qol = 0;
                        
                        next_tag++;
                        break;
                    } else {
                        my[my_buff].params[my[my_buff].lparams].value[my[my_buff].params[my[my_buff].lparams].lvalue++] = tolower(nc);
                    }
                    
                    if(nc == '\\') {
                        my[my_buff].qol++;
                    } else {
                        my[my_buff].qol = 0;
                    }
                }
                
                break;
                
            case 5:
                if(my[my_buff].qo == '\0' && (nc == ' ' || nc == '\t' || nc == '\n')) {
                    break;
                }
                else if(my[my_buff].qo == '\0' && (nc != ' ' && nc != '\t' && nc != '\n' && nc != '"' && nc != '\'')) {
                    my[my_buff].qo = ' ';
                }
                
                if(my[my_buff].qo == '\0') {
                    if(nc == '"') {
                        my[my_buff].qo = '"';
                    }
                    else if(nc == '\'') {
                        my[my_buff].qo = '\'';
                    }
                } else {
                    if((my[my_buff].qo == ' ' && (nc == ' ' || nc == '\t' || nc == '\n')) || (nc == my[my_buff].qo && fmod(my[my_buff].qol,2) == 0)) {
                        my[my_buff].qo = '\0';
                        my[my_buff].qol = 0;
                    }
                    
                    if(nc == '\\') {
                        my[my_buff].qol++;
                    } else {
                        my[my_buff].qol = 0;
                    }
                }
                
                break;
            case 6:
                break;
            default:
                break;
        }
    }
    
    int ti; long ni = i - 2;
    for(ti = tag_ol; ti >= 0; ti--) {
        if(html_tree[ index_ol[ti] ].tag_body_stop == -1){
            html_tree[ index_ol[ti] ].tag_body_stop = ni;
            html_tree[ index_ol[ti] ].tag_stop = ni;
        }
    }
    
    long tl;
    for(tl = html_tree_buff; tl >= 0; tl--) {
        if(html_tree[tl].tag_body_stop != -1)
            break;
        
        html_tree[tl].tag_body_stop = ni;
        html_tree[tl].tag_stop = ni;
    }
    
    free(index_ol);
    
    my_r->list             = html_tree;
    my_r->count            = html_tree_buff;
    my_r->real_count       = html_tree_buff;
    my_r->my_count         = my_buff;
    my_r->my_real_count    = my_real_buff;
    my_r->my               = my;
    my_r->cur_pos          = 0;
    my_r->nco_pos          = 0;
}

int check_tags_alloc(struct tags *tags) {
    if(tags->count >= tags->csize) {
        tags->csize += 1024;
        
        tags->name     = (char **)realloc(tags->name, sizeof(char*) * tags->csize);
        tags->preority = (int *)realloc(tags->preority, sizeof(int) * tags->csize);
        tags->type     = (int *)realloc(tags->type, sizeof(int) * tags->csize);
        tags->extra    = (int *)realloc(tags->extra, sizeof(int) * tags->csize);
        tags->ai       = (int *)realloc(tags->ai, sizeof(int) * tags->csize);
        
        tags->index.tag_id    = (long **)realloc(tags->index.tag_id, sizeof(long *) * tags->csize);
        tags->index.tag_count = (int *)realloc(tags->index.tag_count, tags->csize * sizeof(int));
        tags->index.tag_csize = (int *)realloc(tags->index.tag_csize, tags->csize * sizeof(int));
    }
    
    return tags->csize;
}

int add_tag(struct tags *tags, char *html, struct mem_tag *my) {
    long pr = my->stop_otag - my->start_otag;
    
    if( pr <= 0 )
        return -1;
    
    tags->count++;
    
    check_tags_alloc(tags);
    
    tags->name[ tags->count ] = (char *)malloc(sizeof(char) * (pr + 1));
    
    tags->index.tag_count[tags->count] = -1;
    tags->index.tag_csize[tags->count] = 256;
    tags->index.tag_id[tags->count] = (long *)malloc(sizeof(long) * tags->index.tag_csize[tags->count]);
    
    long i, t = 0;
    for(i = my->start_otag; i <= my->stop_otag; i++ ) {
        tags->name[ tags->count ][t++] = tolower(html[i]);
    }
    tags->name[ tags->count ][t]  = '\0';
    
    tags->preority[ tags->count ] = 0;
    tags->type[ tags->count ]     = TYPE_TAG_INLINE;
    tags->extra[ tags->count ]    = 0;
    tags->ai[ tags->count ]       = AI_NULL;
    
    return tags->count;
}

int add_tag_R(struct tags *tags, char *tagname, size_t size, int preority, int type, int extra, int ai) {
    tags->count++;
    
    check_tags_alloc(tags);
    
    tags->name[ tags->count ] = (char *)malloc(sizeof(char) * size + 1);
    
    tags->index.tag_count[tags->count] = -1;
    tags->index.tag_csize[tags->count] = 256;
    tags->index.tag_id[tags->count] = (long *)malloc(sizeof(long) * tags->index.tag_csize[tags->count]);
    
    long i;
    for(i = 0; i <= size; i++ ) {
        tags->name[ tags->count ][i] = tolower(tagname[i]);
    }
    
    tags->preority[ tags->count ] = preority;
    tags->type[ tags->count ]     = type;
    tags->extra[ tags->count ]    = extra;
    tags->ai[ tags->count ]       = ai;
    
    return tags->count;
}

int cmp_tags(struct tags *tags, char *html, struct mem_tag *my, int offset) {
    int m1;
    int is_cg = -1;
    
    for(m1 = 0; m1 <= tags->count; m1++ ) {
        int m2 = -1;
        
        while( tags->name[m1][++m2] ) {
            long p = my->start_otag + offset + m2;
            
            if(tolower(html[p]) != tags->name[m1][m2]) {
                break;
            }
            else if(my->stop_otag == p && tags->name[m1][m2+1] == '\0') {
                is_cg = m1;
                break;
            }
        }
        
        if(is_cg != -1) {
            break;
        }
    }
    
    if(is_cg == -1 && offset == 0) {
        is_cg = add_tag(tags, html, my);
    }
    
    return is_cg;
}

int get_tag_id(struct tags *tags, char *tagname) {
    int m1;
    int is_cg = -1;
    
    for(m1 = 0; m1 <= tags->count; m1++ ) {
        int m2 = -1;
        
        while( tags->name[m1][++m2] ) {
            if(tolower(tagname[m2]) != tags->name[m1][m2]) {
                break;
            }
            else if(tags->name[m1][m2+1] == '\0' && tagname[m2+1] == '\0') {
                is_cg = m1;
                break;
            }
        }
        
        if(is_cg != -1) {
            break;
        }
    }
    
    return is_cg;
}

long set_position(struct tree_list *my_r, struct html_tree *element) {
    if(element == NULL)
        return -1;
    
    my_r->nco_pos = element->id;
    my_r->cur_pos = element->id;
    return my_r->cur_pos;
}

long get_element_body_size(struct tree_list *my_r, struct html_tree *element) {
    if(element == NULL) {
        return my_r->list[ my_r->cur_pos ].tag_body_stop - my_r->list[ my_r->cur_pos ].tag_body_start;
    }
    
    return element->tag_body_stop - element->tag_body_start;
}

char * get_element_body(struct tree_list *my_r, struct html_tree *element) {
    if(element == NULL) {
        return &my_r->html[ my_r->list[ my_r->cur_pos ].tag_body_start ];
    }
    
    return &my_r->html[element->tag_body_start];
}

struct html_tree * get_curr_element(struct tree_list *my_r) {
    return &my_r->list[my_r->cur_pos];
}

struct html_tree * get_element_by_name(struct tree_list *my_r, char *tagname, long position) {
    int tag_id = get_tag_id(my_r->tags, tagname);
    
    if(tag_id == -1 || my_r->tags->index.tag_count[tag_id] == -1 || position < 0 || my_r->tags->index.tag_count[tag_id] < position)
        return NULL;
    
    return &my_r->list[ my_r->tags->index.tag_id[tag_id][position] ];
}

struct html_tree * get_element_by_name_in_child(struct tree_list *my_r, char *tagname, long position) {
    int tag_id = get_tag_id(my_r->tags, tagname);
    
    if(tag_id == -1 || my_r->tags->index.tag_count[tag_id] == -1 || position < 0 || my_r->tags->index.tag_count[tag_id] < position)
        return NULL;
    
    long i; long cpos = -1; long il = 0;
    for(i = 0; i <= my_r->tags->index.tag_count[tag_id]; i++) {
        if(my_r->cur_pos < my_r->tags->index.tag_id[tag_id][i]) {
            if(il == position) {
                cpos = i;
                break;
            }
            il++;
        }
    }
    
    if(cpos == -1)
        return NULL;
    
    long level = -1;
    for(i = my_r->cur_pos + 1; i <= my_r->count; i++) {
        if(my_r->list[i].inc <= my_r->list[ my_r->cur_pos ].inc) {
            break;
        }
        
        if(my_r->tags->index.tag_id[tag_id][cpos] == i) {
            level = i;
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    return &my_r->list[level];
}

int get_count_element_by_name(struct tree_list *my_r, char *tagname) {
    int tag_id = get_tag_id(my_r->tags, tagname);
    
    if(tag_id == -1)
        return 0;
    
    return my_r->tags->index.tag_count[tag_id] + 1;
}

int get_real_count_element_by_name(struct tree_list *my_r, char *tagname) {
    int tag_id = get_tag_id(my_r->tags, tagname);
    
    if(tag_id == -1)
        return -1;
    
    return my_r->tags->index.tag_count[tag_id];
}

struct html_tree * get_next_element_in_level(struct tree_list *my_r) {
    if(my_r->count > my_r->nco_pos && my_r->list[ my_r->nco_pos + 1 ].inc > my_r->list[ my_r->cur_pos ].inc) {
        my_r->nco_pos++;
        return &my_r->list[my_r->nco_pos];
    }
    
    return NULL;
}

struct html_tree * get_prev_element_in_level(struct tree_list *my_r) {
    if(my_r->nco_pos > 0 && my_r->list[ my_r->nco_pos - 1 ].inc > my_r->list[ my_r->cur_pos ].inc) {
        my_r->nco_pos--;
        return &my_r->list[my_r->nco_pos];
    }
    
    return NULL;
}

struct html_tree * get_next_element_in_level_skip_curr(struct tree_list *my_r) {
    long i; long level = -1;
    for(i = my_r->nco_pos + 1; i <= my_r->count; i++) {
        if(my_r->list[i].inc <= my_r->list[ my_r->cur_pos ].inc) {
            break;
        }
        else if(my_r->list[i].inc <= my_r->list[ my_r->nco_pos ].inc) {
            level = i;
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    
    my_r->nco_pos = level;
    return &my_r->list[level];
}

struct html_tree * get_parent_in_level(struct tree_list *my_r, int set_pos) {
    
    long i; long level = -1;
    for(i = my_r->nco_pos - 1; i >= my_r->cur_pos; i--) {
        if(my_r->list[i].inc < my_r->list[ my_r->nco_pos ].inc) {
            level = i;
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    
    if(set_pos == 1)
        my_r->nco_pos = level;
    
    return &my_r->list[level];
}

struct html_tree * get_next_element(struct tree_list *my_r) {
    if(my_r->count > my_r->cur_pos) {
        my_r->cur_pos++;
        my_r->nco_pos = my_r->cur_pos;
        return &my_r->list[my_r->cur_pos];
    }
    
    return NULL;
}

struct html_tree * get_prev_element(struct tree_list *my_r) {
    if(my_r->cur_pos > 0) {
        my_r->cur_pos--;
        my_r->nco_pos = my_r->cur_pos;
        return &my_r->list[my_r->cur_pos];
    }
    
    return NULL;
}

struct html_tree * get_next_element_skip_curr(struct tree_list *my_r) {
    long i; long level = -1;
    for(i = my_r->cur_pos + 1; i <= my_r->count; i++) {
        if(my_r->list[i].inc <= my_r->list[ my_r->cur_pos ].inc) {
            level = i;
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    
    my_r->nco_pos = level;
    my_r->cur_pos = level;
    return &my_r->list[level];
}

struct html_tree * get_next_element_curr_level(struct tree_list *my_r) {
    long i; long level = -1;
    for(i = my_r->cur_pos + 1; i <= my_r->count; i++) {
        if(my_r->list[i].inc == my_r->list[ my_r->cur_pos ].inc) {
            level = i;
            break;
        }
        else if(my_r->list[i].inc < my_r->list[ my_r->cur_pos ].inc) {
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    
    my_r->nco_pos = level;
    my_r->cur_pos = level;
    return &my_r->list[level];
}

struct html_tree * get_prev_element_curr_level(struct tree_list *my_r) {
    
    long i; long level = -1;
    for(i = my_r->cur_pos - 1; i >= 0; i--) {
        if(my_r->list[i].inc == my_r->list[ my_r->cur_pos ].inc) {
            level = i;
            break;
        }
        else if(my_r->list[i].inc < my_r->list[ my_r->cur_pos ].inc) {
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    
    my_r->nco_pos = level;
    my_r->cur_pos = level;
    return &my_r->list[level];
}

struct html_tree * get_child(struct tree_list *my_r, long pos) {
    
    long level = -1;
    int next_level = my_r->list[ my_r->cur_pos ].inc + 1;
    
    long i;
    for(i = my_r->cur_pos + 1; i <= my_r->count; i++) {
        if(my_r->list[i].inc == next_level) {
            pos--;
            if(pos == -1) {
                level = i;
                break;
            }
        }
        else if(my_r->list[i].inc <= my_r->list[ my_r->cur_pos ].inc) {
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    
    my_r->nco_pos = level;
    my_r->cur_pos = level;
    return &my_r->list[level];
}

struct html_tree * get_child_n(struct tree_list *my_r, long pos) {
    
    long level = -1;
    int next_level = my_r->list[ my_r->cur_pos ].inc + 1;
    
    long i;
    for(i = my_r->cur_pos + 1; i <= my_r->count; i++) {
        if(my_r->list[i].inc == next_level) {
            pos--;
            if(pos == -1) {
                level = i;
                break;
            }
        }
        else if(my_r->list[i].inc <= my_r->list[ my_r->cur_pos ].inc) {
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    
    return &my_r->list[level];
}

struct html_tree * get_parent(struct tree_list *my_r) {
    
    long i; long level = -1;
    for(i = my_r->cur_pos - 1; i >= 0; i--) {
        if(my_r->list[i].inc < my_r->list[ my_r->cur_pos ].inc) {
            level = i;
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    
    my_r->nco_pos = level;
    my_r->cur_pos = level;
    return &my_r->list[level];
}

struct html_tree * get_child_by_tree(struct tree_list *my_r, struct html_tree *html_tree) {
    
    long i; long level = -1;
    for(i = html_tree->id + 1; i <= my_r->count; i++) {
        if(my_r->list[i].inc > html_tree->inc) {
            level = i;
            break;
        }
        else if(my_r->list[i].inc <= html_tree->inc) {
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    return &my_r->list[level];
}

struct mem_params * find_param_by_key_in_element(struct mem_tag *my, char *key) {
    long p;
    struct mem_params *np = NULL;
    
    for (p = 0; p <= my->lparams; p++) {
        long k;
        for (k = 0; k <= my->params[p].lkey; k++) {
            if(my->params[p].key[k] != key[k] || ((my->params[p].key[k] != '\0' && key[k] == '\0') || (my->params[p].key[k] == '\0' && key[k] != '\0'))) {
                break;
            }
            else if(my->params[p].key[k] == '\0' && key[k] == '\0') {
                np = &my->params[p];
                break;
            }
        }
    }
    
    return np;
}

void clean_tree(struct tree_list * my_r) {
    int di;
    for(di = 0; di <= my_r->my_real_count; di++) {
        int si;
        
        for(si = 0; si <= my_r->my[di].lparams; si++) {
            free(my_r->my[di].params[si].key);
            free(my_r->my[di].params[si].value);
        }
        
        free(my_r->my[di].params);
    }
    
    my_r->my_count      = -1;
    my_r->my_real_count = -1;
    
    my_r->count         = -1;
    my_r->real_count    = -1;
    
    my_r->cur_pos       = 0;
    my_r->nco_pos       = 0;
    
    if(my_r->my != NULL)
        free(my_r->my);
    
    if(my_r->tags != NULL) {
        for(di = 0; di <= my_r->tags->count; di++) {
            free(my_r->tags->index.tag_id[di]);
            free(my_r->tags->name[di]);
        }
        
        free(my_r->tags->index.tag_count);
        free(my_r->tags->index.tag_csize);
        free(my_r->tags->index.tag_id);
        free(my_r->tags->name);
        free(my_r->tags->preority);
        free(my_r->tags->type);
        free(my_r->tags->extra);
        free(my_r->tags->ai);
    }
    
    if(my_r->list != NULL)
        free(my_r->list);
}

struct tree_entity * create_entity_tree(void) {
    struct tree_entity *entities = (struct tree_entity *)malloc(sizeof(struct tree_entity) * 128);
    
    int i;
    for(i = 0; i < 128; i++) {
        entities[i].count = -1;
        entities[i].next  = NULL;
        entities[i].value[0] = '\0';
        entities[i].level = 0;
    }
    
    add_entity(entities, "AElig", "Æ");
    add_entity(entities, "Aacute", "Á");
    add_entity(entities, "Acirc", "Â");
    add_entity(entities, "Agrave", "À");
    add_entity(entities, "Alpha", "Α");
    add_entity(entities, "Aring", "Å");
    add_entity(entities, "Atilde", "Ã");
    add_entity(entities, "Auml", "Ä");
    add_entity(entities, "Beta", "Β");
    add_entity(entities, "Ccedil", "Ç");
    add_entity(entities, "Chi", "Χ");
    add_entity(entities, "Dagger", "‡");
    add_entity(entities, "Delta", "Δ");
    add_entity(entities, "ETH", "Ð");
    add_entity(entities, "Eacute", "É");
    add_entity(entities, "Ecirc", "Ê");
    add_entity(entities, "Egrave", "È");
    add_entity(entities, "Epsilon", "Ε");
    add_entity(entities, "Eta", "Η");
    add_entity(entities, "Euml", "Ë");
    add_entity(entities, "Gamma", "Γ");
    add_entity(entities, "Iacute", "Í");
    add_entity(entities, "Icirc", "Î");
    add_entity(entities, "Igrave", "Ì");
    add_entity(entities, "Iota", "Ι");
    add_entity(entities, "Iuml", "Ï");
    add_entity(entities, "Kappa", "Κ");
    add_entity(entities, "Lambda", "Λ");
    add_entity(entities, "Mu", "Μ");
    add_entity(entities, "Ntilde", "Ñ");
    add_entity(entities, "Nu", "Ν");
    add_entity(entities, "OElig", "Œ");
    add_entity(entities, "Oacute", "Ó");
    add_entity(entities, "Ocirc", "Ô");
    add_entity(entities, "Ograve", "Ò");
    add_entity(entities, "Omega", "Ω");
    add_entity(entities, "Omicron", "Ο");
    add_entity(entities, "Oslash", "Ø");
    add_entity(entities, "Otilde", "Õ");
    add_entity(entities, "Ouml", "Ö");
    add_entity(entities, "Phi", "Φ");
    add_entity(entities, "Pi", "Π");
    add_entity(entities, "Prime", "″");
    add_entity(entities, "Psi", "Ψ");
    add_entity(entities, "Rho", "Ρ");
    add_entity(entities, "Scaron", "Š");
    add_entity(entities, "Sigma", "Σ");
    add_entity(entities, "THORN", "Þ");
    add_entity(entities, "Tau", "Τ");
    add_entity(entities, "Theta", "Θ");
    add_entity(entities, "Uacute", "Ú");
    add_entity(entities, "Ucirc", "Û");
    add_entity(entities, "Ugrave", "Ù");
    add_entity(entities, "Upsilon", "Υ");
    add_entity(entities, "Uuml", "Ü");
    add_entity(entities, "Xi", "Ξ");
    add_entity(entities, "Yacute", "Ý");
    add_entity(entities, "Yuml", "Ÿ");
    add_entity(entities, "Zeta", "Ζ");
    add_entity(entities, "aacute", "á");
    add_entity(entities, "acirc", "â");
    add_entity(entities, "acute", "´");
    add_entity(entities, "aelig", "æ");
    add_entity(entities, "agrave", "à");
    add_entity(entities, "alefsym", "ℵ");
    add_entity(entities, "alpha", "α");
    add_entity(entities, "amp", "&");
    add_entity(entities, "and", "∧");
    add_entity(entities, "ang", "∠");
    add_entity(entities, "apos", "'");
    add_entity(entities, "aring", "å");
    add_entity(entities, "asymp", "≈");
    add_entity(entities, "atilde", "ã");
    add_entity(entities, "auml", "ä");
    add_entity(entities, "bdquo", "„");
    add_entity(entities, "beta", "β");
    add_entity(entities, "brvbar", "¦");
    add_entity(entities, "bull", "•");
    add_entity(entities, "cap", "∩");
    add_entity(entities, "ccedil", "ç");
    add_entity(entities, "cedil", "¸");
    add_entity(entities, "cent", "¢");
    add_entity(entities, "chi", "χ");
    add_entity(entities, "circ", "ˆ");
    add_entity(entities, "clubs", "♣");
    add_entity(entities, "cong", "≅");
    add_entity(entities, "copy", "©");
    add_entity(entities, "crarr", "↵");
    add_entity(entities, "cup", "∪");
    add_entity(entities, "curren", "¤");
    add_entity(entities, "dArr", "⇓");
    add_entity(entities, "dagger", "†");
    add_entity(entities, "darr", "↓");
    add_entity(entities, "deg", "°");
    add_entity(entities, "delta", "δ");
    add_entity(entities, "diams", "♦");
    add_entity(entities, "divide", "÷");
    add_entity(entities, "eacute", "é");
    add_entity(entities, "ecirc", "ê");
    add_entity(entities, "egrave", "è");
    add_entity(entities, "empty", "∅");
    add_entity(entities, "emsp", " ");
    add_entity(entities, "ensp", " ");
    add_entity(entities, "epsilon", "ε");
    add_entity(entities, "equiv", "≡");
    add_entity(entities, "eta", "η");
    add_entity(entities, "eth", "ð");
    add_entity(entities, "euml", "ë");
    add_entity(entities, "euro", "€");
    add_entity(entities, "exist", "∃");
    add_entity(entities, "fnof", "ƒ");
    add_entity(entities, "forall", "∀");
    add_entity(entities, "frac12", "½");
    add_entity(entities, "frac14", "¼");
    add_entity(entities, "frac34", "¾");
    add_entity(entities, "frasl", "⁄");
    add_entity(entities, "gamma", "γ");
    add_entity(entities, "ge", "≥");
    add_entity(entities, "gt", ">");
    add_entity(entities, "hArr", "⇔");
    add_entity(entities, "harr", "↔");
    add_entity(entities, "hearts", "♥");
    add_entity(entities, "hellip", "…");
    add_entity(entities, "iacute", "í");
    add_entity(entities, "icirc", "î");
    add_entity(entities, "iexcl", "¡");
    add_entity(entities, "igrave", "ì");
    add_entity(entities, "image", "ℑ");
    add_entity(entities, "infin", "∞");
    add_entity(entities, "int", "∫");
    add_entity(entities, "iota", "ι");
    add_entity(entities, "iquest", "¿");
    add_entity(entities, "isin", "∈");
    add_entity(entities, "iuml", "ï");
    add_entity(entities, "kappa", "κ");
    add_entity(entities, "lArr", "⇐");
    add_entity(entities, "lambda", "λ");
    add_entity(entities, "lang", "〈");
    add_entity(entities, "laquo", "«");
    add_entity(entities, "larr", "←");
    add_entity(entities, "lceil", "⌈");
    add_entity(entities, "ldquo", "“");
    add_entity(entities, "le", "≤");
    add_entity(entities, "lfloor", "⌊");
    add_entity(entities, "lowast", "∗");
    add_entity(entities, "loz", "◊");
    add_entity(entities, "lrm", "\xE2\x80\x8E");
    add_entity(entities, "lsaquo", "‹");
    add_entity(entities, "lsquo", "‘");
    add_entity(entities, "lt", "<");
    add_entity(entities, "macr", "¯");
    add_entity(entities, "mdash", "—");
    add_entity(entities, "micro", "µ");
    add_entity(entities, "middot", "·");
    add_entity(entities, "minus", "−");
    add_entity(entities, "mu", "μ");
    add_entity(entities, "nabla", "∇");
    add_entity(entities, "nbsp", " ");
    add_entity(entities, "ndash", "–");
    add_entity(entities, "ne", "≠");
    add_entity(entities, "ni", "∋");
    add_entity(entities, "not", "¬");
    add_entity(entities, "notin", "∉");
    add_entity(entities, "nsub", "⊄");
    add_entity(entities, "ntilde", "ñ");
    add_entity(entities, "nu", "ν");
    add_entity(entities, "oacute", "ó");
    add_entity(entities, "ocirc", "ô");
    add_entity(entities, "oelig", "œ");
    add_entity(entities, "ograve", "ò");
    add_entity(entities, "oline", "‾");
    add_entity(entities, "omega", "ω");
    add_entity(entities, "omicron", "ο");
    add_entity(entities, "oplus", "⊕");
    add_entity(entities, "or", "∨");
    add_entity(entities, "ordf", "ª");
    add_entity(entities, "ordm", "º");
    add_entity(entities, "oslash", "ø");
    add_entity(entities, "otilde", "õ");
    add_entity(entities, "otimes", "⊗");
    add_entity(entities, "ouml", "ö");
    add_entity(entities, "para", "¶");
    add_entity(entities, "part", "∂");
    add_entity(entities, "permil", "‰");
    add_entity(entities, "perp", "⊥");
    add_entity(entities, "phi", "φ");
    add_entity(entities, "pi", "π");
    add_entity(entities, "piv", "ϖ");
    add_entity(entities, "plusmn", "±");
    add_entity(entities, "pound", "£");
    add_entity(entities, "prime", "′");
    add_entity(entities, "prod", "∏");
    add_entity(entities, "prop", "∝");
    add_entity(entities, "psi", "ψ");
    add_entity(entities, "quot", "\"");
    add_entity(entities, "rArr", "⇒");
    add_entity(entities, "radic", "√");
    add_entity(entities, "rang", "〉");
    add_entity(entities, "raquo", "»");
    add_entity(entities, "rarr", "→");
    add_entity(entities, "rceil", "⌉");
    add_entity(entities, "rdquo", "”");
    add_entity(entities, "real", "ℜ");
    add_entity(entities, "reg", "®");
    add_entity(entities, "rfloor", "⌋");
    add_entity(entities, "rho", "ρ");
    add_entity(entities, "rlm", "\xE2\x80\x8F");
    add_entity(entities, "rsaquo", "›");
    add_entity(entities, "rsquo", "’");
    add_entity(entities, "sbquo", "‚");
    add_entity(entities, "scaron", "š");
    add_entity(entities, "sdot", "⋅");
    add_entity(entities, "sect", "§");
    add_entity(entities, "shy", "\xC2\xAD");
    add_entity(entities, "sigma", "σ");
    add_entity(entities, "sigmaf", "ς");
    add_entity(entities, "sim", "∼");
    add_entity(entities, "spades", "♠");
    add_entity(entities, "sub", "⊂");
    add_entity(entities, "sube", "⊆");
    add_entity(entities, "sum", "∑");
    add_entity(entities, "sup", "⊃");
    add_entity(entities, "sup1", "¹");
    add_entity(entities, "sup2", "²");
    add_entity(entities, "sup3", "³");
    add_entity(entities, "supe", "⊇");
    add_entity(entities, "szlig", "ß");
    add_entity(entities, "tau", "τ");
    add_entity(entities, "there4", "∴");
    add_entity(entities, "theta", "θ");
    add_entity(entities, "thetasym", "ϑ");
    add_entity(entities, "thinsp", " ");
    add_entity(entities, "thorn", "þ");
    add_entity(entities, "tilde", "˜");
    add_entity(entities, "times", "×");
    add_entity(entities, "trade", "™");
    add_entity(entities, "uArr", "⇑");
    add_entity(entities, "uacute", "ú");
    add_entity(entities, "uarr", "↑");
    add_entity(entities, "ucirc", "û");
    add_entity(entities, "ugrave", "ù");
    add_entity(entities, "uml", "¨");
    add_entity(entities, "upsih", "ϒ");
    add_entity(entities, "upsilon", "υ");
    add_entity(entities, "uuml", "ü");
    add_entity(entities, "weierp", "℘");
    add_entity(entities, "xi", "ξ");
    add_entity(entities, "yacute", "ý");
    add_entity(entities, "yen", "¥");
    add_entity(entities, "yuml", "ÿ");
    add_entity(entities, "zeta", "ζ");
    add_entity(entities, "zwj", "\xE2\x80\x8D");
    add_entity(entities, "zwnj", "\xE2\x80\x8C");
    
    return entities;
}

void _add_entity(struct tree_entity *entities, char *key, char *value, int i) {
    if(entities[key[i]].next == NULL) {
        entities[key[i]].next = (struct tree_entity *)malloc(sizeof(struct tree_entity) * 128);
        
        int k;
        for(k = 0; k < 128; k++) {
            entities[key[i]].next[k].count = -1;
            entities[key[i]].next[k].next  = NULL;
            entities[key[i]].next[k].value[0] = '\0';
            entities[key[i]].next[k].level = 0;
        }
    }
    
    int next_i = i + 1;
    if(key[next_i] == '\0') {
        int m = -1;
        while (value[++m]) {
            entities[ key[i] ].value[m] = value[m];
        }
        
        entities[ key[i] ].value[m] = '\0';
        entities[ key[i] ].level = i;
        entities[ key[i] ].count++;
    } else {
        _add_entity(entities[ key[i] ].next, key, value, i + 1);
    }
}

void add_entity(struct tree_entity *entities, char *key, char *value) {
    _add_entity(entities, key, value, 0);
}

struct tree_entity * _check_entity(struct tree_entity *entities, char *name, int i) {
    if(name[i] == '\0')
        return NULL;
    
    int next_i = i + 1;
    if(name[next_i] == '\0') {
        if(entities[name[i]].count != -1) {
            return &entities[name[i]];
        }
        return NULL;
    }
    
    if(entities[name[i]].next == NULL || entities[name[i]].next[name[next_i]].next == NULL) {
        if(entities[name[i]].count != -1) {
            return &entities[name[i]];
        }
        else {
            return NULL;
        }
    }
    
    return _check_entity(entities[name[i]].next, name, i + 1);
}

struct tree_entity * check_entity(struct tree_entity *entities, char *name) {
    return _check_entity(entities, name, 0);
}

void clean_tree_entity(struct tree_entity *entities) {
    int i;
    for(i = 0; i < 128; i++) {
        if(entities[i].next != NULL) {
            clean_tree_entity(entities[i].next);
            free(entities[i].next);
        }
    }
}

MODULE = HTML::Content::Extractor  PACKAGE = HTML::Content::Extractor

PROTOTYPES: DISABLE

HTML::Content::Extractor
new(char * class, ...)
    CODE:
        htmltag_t *my_r = malloc(sizeof(htmltag_t));
        
        my_r->entities = create_entity_tree();
        my_r->tags = NULL;
        my_r->list = NULL;
        my_r->my   = NULL;
        
        my_r->my_count      = -1;
        my_r->my_real_count = -1;
        
        RETVAL = my_r;
    OUTPUT:
        RETVAL

void
analyze(my_r, html)
    HTML::Content::Extractor my_r;
    char *html;

    CODE:
        //setbuf(stdout, NULL);
        
        clean_tree(my_r);
        
        if(my_r->tags)
            free(my_r->tags);
        
        struct tags *tags = malloc(sizeof(struct tags));
        tags->count = -1;
        tags->csize = -1;
        my_r->tags = tags;
        
        my_r->html = html;
        html_tree(my_r);
        
        struct max_element my_max = {0, NULL};
        struct html_tree * max_element = check_html(my_r, &my_max);
        set_position(my_r, max_element);

SV*
get_main_text(my_r, is_utf8 = 1)
    HTML::Content::Extractor my_r;
    int is_utf8;
    
    CODE:
        if(my_r->list == NULL || my_r->my == NULL || my_r->tags == NULL) {
            RETVAL = newSVsv(&PL_sv_undef);
        }
        else {
            struct lbuffer main_buff = {-1, 1024 * 1024, NULL};
            get_text_without_element(my_r, &main_buff);
            clean_text(my_r->entities, &main_buff);
            
            if(main_buff.i < 0) {
                RETVAL = newSVsv(&PL_sv_undef);
            } else {
                if(is_utf8) {
                    SV *nm = newSVpv(main_buff.buff, main_buff.i);
                    SvUTF8_on(nm);
                    RETVAL = nm;
                } else {
                    RETVAL = newSVpv(main_buff.buff, main_buff.i);
                }
            }
            
            free(main_buff.buff);
        }
    OUTPUT:
        RETVAL

SV*
get_main_text_with_elements(my_r, is_utf8 = 1, elements_ref = &PL_sv_undef)
    HTML::Content::Extractor my_r;
    int is_utf8;
    SV* elements_ref;
    
    CODE:
        AV* array;
        char **elements;
        int elem_size = -1;
        
        if(SvROK(elements_ref)) {
            array = (AV*)SvRV(elements_ref);
            
            elem_size = av_len(array);
            elements = (char **)malloc(sizeof(char *) * elem_size + 1);
            
            char *tmp;
            int i;
            STRLEN len_s;
            for (i = 0; i <= elem_size; i++) {
                //SV *elem = av_shift(array);
                SV** elem = av_fetch(array, i, 0);
                if(elem != NULL) {
                    elements[i] = (char *)SvPV(*elem, len_s);
                }
            }
        }
        
        if(my_r->list == NULL || my_r->my == NULL || my_r->tags == NULL) {
            RETVAL = newSVsv(&PL_sv_undef);
        }
        else {
            struct lbuffer main_buff = {-1, 1024 * 1024, NULL};
            get_text_with_element(my_r, &main_buff, elements, elem_size);
            
            if(main_buff.i < 0) {
                RETVAL = newSVsv(&PL_sv_undef);
            } else {
                if(is_utf8) {
                    SV *nm = newSVpv(main_buff.buff, main_buff.i);
                    SvUTF8_on(nm);
                    RETVAL = nm;
                } else {
                    RETVAL = newSVpv(main_buff.buff, main_buff.i);
                }
            }
            
            free(main_buff.buff);
            if(elem_size > -1) {
                free(elements);
            }
        }
    OUTPUT:
        RETVAL

SV*
get_raw_text(my_r, is_utf8 = 1)
    HTML::Content::Extractor my_r;
    int is_utf8;
    
    CODE:
        if(my_r->list == NULL || my_r->my == NULL || my_r->tags == NULL) {
            RETVAL = newSVsv(&PL_sv_undef);
        }
        else {
            struct lbuffer main_buff = {-1, 1024 * 1024, NULL};
            get_raw_text(my_r, &main_buff);
            
            if(main_buff.i < 0) {
                RETVAL = newSVsv(&PL_sv_undef);
            } else {
                if(is_utf8) {
                    SV *nm = newSVpv(main_buff.buff, main_buff.i);
                    SvUTF8_on(nm);
                    RETVAL = nm;
                } else {
                    RETVAL = newSVpv(main_buff.buff, main_buff.i);
                }
            }
            
            free(main_buff.buff);
        }
    OUTPUT:
        RETVAL

SV*
get_main_images(my_r, is_utf8 = 1)
    HTML::Content::Extractor my_r;
    int is_utf8;
    
    CODE:
        AV* array = newAV();
        
        if(my_r->list == NULL || my_r->my == NULL || my_r->tags == NULL) {
            RETVAL = newRV_noinc((SV*)array);
        }
        else {
            struct mlist list = {-1, 128};
            get_text_images_href(my_r, &list, 0);
            
            if(list.i < 0) {
                RETVAL = newRV_noinc((SV*)array);
            } else {
                if(is_utf8) {
                    int i;
                    for (i = 0; i <= list.i; i++) {
                        SV *nm = newSVpv(list.buff[i], 0);
                        SvUTF8_on(nm);
                        av_push(array, nm);
                    }
                    
                    RETVAL = newRV_noinc((SV*)array);
                } else {
                    int i;
                    for (i = 0; i <= list.i; i++) {
                        av_push(array, newSVpv(list.buff[i], 0));
                    }
                    
                    RETVAL = newRV_noinc((SV*)array);
                }
            }
            
            unsigned int im;
            for (im = 0; im <= list.i; im++) {
                free(list.buff[im]);
            }
            
            free(list.buff);
        }
    OUTPUT:
        RETVAL


void
DESTROY(my_r)
    HTML::Content::Extractor my_r;
    
    CODE:
        clean_tree_entity(my_r->entities);
        if(my_r->entities)
            free(my_r->entities);
        
        if(my_r) {
            clean_tree(my_r);
            
            if(my_r->tags)
                free(my_r->tags);
            
            free(my_r);
        }

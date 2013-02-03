//
//  Created by Alexander Borisov on 10.01.13.
//  Copyright (c) 2013 Alexander Borisov. All rights reserved.
//

#include <stdio.h>
#include <ctype.h>
#include <math.h>
#include <stdlib.h>
#include <unistd.h>
#include <memory.h>

#define TYPE_TAG_IS_OPEN   100
#define TYPE_TAG_IS_CLOSE  200
#define TYPE_TAG_IS_SIMPLE 1

#define TYPE_TAG_BLOCK  10
#define TYPE_TAG_INLINE 11
#define TYPE_TAG_SIMPLE 12
#define TYPE_TAG_ONE    13
#define TYPE_TAG_TEXT   14

#define DEFAULT_TAG_ID  0

#define EXTRA_TAG_CLOSE_IF_BLOCK 1
#define EXTRA_TAG_CLOSE_IF_SELF  2

#define AI_BUFF 4
#define AI_NULL 0
#define AI_TEXT 1
#define AI_LINK 2
#define AI_IMG  3

struct mem_params {
    char *key;
    int  lkey;
    int  lkey_size;
    char *value;
    int  lvalue;
    int  lvalue_size;
};

struct mem_tag {
    char qo;
    int qol;
    
    long start_otag;
    long stop_otag;
    
    int type;
    int tag_id;
    
    long lparams;
    long lparams_size;
    struct mem_params *params;
};

struct return_list {
    long count;
    long real_count;
    struct mem_tag *list;
};

struct tags_index {
    long **tag_id;
    int *tag_count;
    int *tag_csize;
};

struct tags {
    int count;
    int csize;
    char **name;
    int *preority;
    int *type;
    int *extra;
    int *ai;
    struct tags_index index;
};

struct html_tree {
    long id;
    
    long tag_body_start;
    long tag_body_stop;
    long tag_start;
    long tag_stop;
    
    int tag_id;
    int inc;
    long my_id;
    int count_element;
    int count_element_in;
    int counts[AI_BUFF];
    int counts_in[AI_BUFF];
    int count_word;
};

struct tree_list {
    long count;
    long real_count;
    struct html_tree *list;
    
    struct mem_tag *my;
    long my_count;
    long my_real_count;
    
    long cur_pos;
    long nco_pos;
    char *html;
    struct tags *tags;
    struct tree_entity *entities;
};

struct max_element {
    long count_words;
    struct html_tree *element;
};

struct lbuffer {
    long i;
    size_t buff_size;
    char *buff;
};

struct mlist {
    long i;
    size_t buff_size;
    char **buff;
};

struct tree_entity {
    int count;
    struct tree_entity *next;
    char value[5];
    int level;
};

typedef struct tree_list my_tree_list;

int add_tag_R(struct tags *, char *, size_t, int, int, int, int);
int add_tag(struct tags *, char *, struct mem_tag *);

int init_tags(struct tags *);
int check_tags_alloc(struct tags *);

void html_tree(struct tree_list *);

int get_tag_id(struct tags *, char *);

struct html_tree * get_child(struct tree_list *, long);
struct html_tree * get_child_n(struct tree_list *, long);
struct html_tree * get_parent(struct tree_list *);

struct html_tree * get_curr_element(struct tree_list *);

struct html_tree * get_next_element_curr_level(struct tree_list *);
struct html_tree * get_prev_element_curr_level(struct tree_list *);

struct html_tree * get_next_element_in_level(struct tree_list *);
struct html_tree * get_prev_element_in_level(struct tree_list *);
struct html_tree * get_next_element_in_level_skip_curr(struct tree_list *);
struct html_tree * get_parent_in_level(struct tree_list *, int);

struct html_tree * get_next_element_skip_curr(struct tree_list *);

struct html_tree * get_next_element(struct tree_list *);
struct html_tree * get_prev_element(struct tree_list *);

struct html_tree * get_element_by_name(struct tree_list *, char *, long);
struct html_tree * get_element_by_name_in_child(struct tree_list *, char *, long);

int get_count_element_by_name(struct tree_list *, char *);
int get_real_count_element_by_name(struct tree_list *, char *);

long set_position(struct tree_list *, struct html_tree *);

long get_element_body_size(struct tree_list *, struct html_tree *);
char * get_element_body(struct tree_list *, struct html_tree *);

struct mem_params * find_param_by_key_in_element(struct mem_tag *, char *);

struct html_tree * check_html(struct tree_list *, struct max_element *);

void get_raw_text(struct tree_list *, struct lbuffer *);
void get_text_without_element(struct tree_list *, struct lbuffer *);
void get_text_with_element(struct tree_list *, struct lbuffer *, char **, int);
void get_text_images_href(struct tree_list *, struct mlist *, int);

void clean_text(struct tree_entity *, struct lbuffer *);

int cmp_tags(struct tags *, char *, struct mem_tag *, int);

void clean_tree(struct tree_list *);

struct tree_entity * create_entity_tree(void);
void clean_tree_entity(struct tree_entity *);

struct tree_entity * check_entity(struct tree_entity *, char *);
void add_entity(struct tree_entity *, char *, char *);

typedef struct tree_list htmltag_t;
